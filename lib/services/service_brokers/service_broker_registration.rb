module VCAP::Services::ServiceBrokers
  class ServiceBrokerRegistration
    attr_reader :broker

    def initialize(broker)
      @broker = broker
      @warnings = []
    end

    def create
      return unless broker.valid?
      validate_catalog!
      broker.save

      begin
        synchronize_dashboard_clients!

        broker.db.transaction do
          synchronize_services_and_plans!
        end
      rescue => e
        broker.destroy
        raise e
      end
      return self
    end

    def update
      return unless broker.valid?
      validate_catalog!
      synchronize_dashboard_clients!

      broker.db.transaction do
        broker.save
        synchronize_services_and_plans!
      end
      return self
    end

    def errors
      broker.errors
    end

    def warnings
      @warnings
    end

    private

    def synchronize_dashboard_clients!
      unless client_manager.synchronize_clients_with_catalog(catalog)
        raise_humanized_exception(client_manager.errors)
      end

      if client_manager.has_warnings?
        client_manager.warnings.each { |warning| warnings << warning }
      end
    end

    def synchronize_services_and_plans!
      service_manager.sync_services_and_plans

      if service_manager.has_warnings?
        service_manager.warnings.each { |warning| warnings << warning }
      end
    end

    def validate_catalog!
      raise_humanized_exception(catalog.errors) unless catalog.valid?
    end

    def client_manager
      @client_manager ||= VCAP::Services::SSO::DashboardClientManager.new(broker)
    end

    def service_manager
      @service_manager ||= ServiceManager.new(catalog)
    end

    def catalog
      @catalog ||= V2::Catalog.new(broker, broker.client.catalog)
    end

    def formatter
      @formatter ||= ValidationErrorsFormatter.new
    end

    def raise_humanized_exception(errors)
      humanized_message = formatter.format(errors)
      raise VCAP::Errors::ApiError.new_from_details("ServiceBrokerCatalogInvalid", humanized_message)
    end
  end
end