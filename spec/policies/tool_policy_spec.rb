require 'rails_helper'

describe ToolPolicy do
  let(:logingov_admin) { build(:logingov_admin) }
  let(:team_user) { build(:user) }
  let(:other_user) { build(:user) }
  let(:team) { build(:team) }
  let(:app) { create(:service_provider, team:) }

  before do
    team.users << team_user
  end

  permissions :can_view_request_details? do
    context 'when login.gov admin' do
      it 'allows login.gov admins to view request details' do
        expect(ToolPolicy).to permit(logingov_admin, app)
      end

      it 'allows team members to view request details' do
        expect(ToolPolicy).to permit(team_user, app)
      end

      it 'does not allow random users to view request details' do
        expect(ToolPolicy).to_not permit(other_user, app)
      end
    end
  end
end
