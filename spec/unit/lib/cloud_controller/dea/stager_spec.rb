require 'spec_helper'

module VCAP::CloudController
  module Dea
    describe Stager do
      let(:config) do
        instance_double(Config)
      end

      let(:message_bus) do
        instance_double(CfMessageBus::MessageBus, publish: nil)
      end

      let(:dea_pool) do
        instance_double(Dea::Pool)
      end

      let(:stager_pool) do
        instance_double(Dea::StagerPool)
      end

      let(:runners) do
        instance_double(Runners)
      end

      let(:runner) { double(:Runner) }

      subject(:stager) do
        Stager.new(thing_to_stage, config, message_bus, dea_pool, stager_pool, runners)
      end

      let(:stager_task) do
        double(AppStagerTask)
      end

      let(:reply_json_error) { nil }
      let(:reply_error_info) { nil }
      let(:detected_buildpack) { nil }
      let(:detected_start_command) { 'wait_for_godot' }
      let(:buildpack_key) { nil }
      let(:droplet_hash) { 'droplet-sha1' }
      let(:reply_json) do
        {
          'task_id' => 'task-id',
          'task_log' => 'task-log',
          'task_streaming_log_url' => nil,
          'detected_buildpack' => detected_buildpack,
          'buildpack_key' => buildpack_key,
          'procfile' => { 'web' => "while true; do { echo -e 'HTTP/1.1 200 OK\\r\\n'; echo custom buildpack contents - cache not found; } | nc -l $PORT; done" },
          'detected_start_command' => detected_start_command,
          'error' => reply_json_error,
          'error_info' => reply_error_info,
          'droplet_sha1' => droplet_hash,
        }
      end
      let(:staging_result) { StagingResponse.new(reply_json) }
      let(:staging_error) { nil }

      it_behaves_like 'a stager' do
        let(:thing_to_stage) { nil }
      end

      describe '#stage' do
        let(:thing_to_stage) { AppFactory.make }

        before do
          allow(AppStagerTask).to receive(:new).and_return(stager_task)
          allow(stager_task).to receive(:stage).and_yield('fake-staging-result').and_return('fake-stager-response')
          allow(runners).to receive(:runner_for_app).with(thing_to_stage).and_return(runner)
          allow(runner).to receive(:start).with('fake-staging-result')
        end

        it 'stages the app with a stager task' do
          stager.stage
          expect(stager_task).to have_received(:stage)
          expect(AppStagerTask).to have_received(:new).with(config,
                                                            message_bus,
                                                            thing_to_stage,
                                                            dea_pool,
                                                            stager_pool,
                                                            an_instance_of(CloudController::Blobstore::UrlGenerator))
        end

        it 'starts the app with the returned staging result' do
          stager.stage
          expect(runner).to have_received(:start).with('fake-staging-result')
        end

        it 'records the stager response on the app' do
          stager.stage
          expect(thing_to_stage.last_stager_response).to eq('fake-stager-response')
        end
      end
    end
  end
end
