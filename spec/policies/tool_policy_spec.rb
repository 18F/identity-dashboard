require 'rails_helper'

describe ToolPolicy do
  let(:admin_user) { build(:admin) }
  let(:team_user) { build(:user) }
  let(:other_user) { build(:user) }
  let(:team) { build(:team) }
  let(:app) { create(:service_provider, team:) }

  before do
    team.users << team_user
  end

  permissions :can_view_request_details? do
    context 'admin user' do
      it 'allows admin users to view request details' do
        expect(ToolPolicy).to permit(admin_user, app)
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
