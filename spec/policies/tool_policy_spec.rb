require 'rails_helper'

describe ToolPolicy do
  let(:logingov_admin) { create(:logingov_admin) }
  let(:team) { build(:team) }
  let(:team_membership) { build(:team_membership, team:) }
  let(:team_user) { team_membership.user }
  let(:other_user) { build(:user) }
  let(:app) { create(:service_provider, team:) }

  permissions :can_view_request_details? do
    it 'allows login.gov admins to view request details' do
      expect(ToolPolicy).to permit(logingov_admin, app)
    end

    it 'allows team members to view request details' do
      expect(ToolPolicy).to permit(team_user, app)
    end

    it 'does not allow reports readonly team users' do
      team_membership.update!(role: Role.find_by(name: :partner_reports_readonly))
      expect(ToolPolicy).to_not permit(team_user, app)
    end

    it 'does not allow random users to view request details' do
      expect(ToolPolicy).to_not permit(other_user, app)
    end
  end
end
