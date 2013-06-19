require_relative 'abstract_presenter'
require_relative 'organization_presenter'

class UserSummaryPresenter < AbstractPresenter
  def entity_hash
    {
      organizations: present_orgs(@object.organizations),
      managed_organizations: present_orgs(@object.managed_organizations),
      spaces: present_spaces(@object.spaces),
      managed_spaces: present_spaces(@object.managed_spaces)
    }
  end

  private

  def present_orgs(orgs)
    orgs.map { |org| OrganizationPresenter.new(org).to_hash }
  end

  def present_spaces(spaces)
    spaces.map { |space| SpacePresenter.new(space).to_hash }
  end
end
