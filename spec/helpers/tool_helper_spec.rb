require 'rails_helper'
describe TeamHelper do
  include Devise::Test::ControllerHelpers

  let(:team) { create(:team) }
  let(:sp) { create(:service_provider, team:) }
  let(:team_user) { create(:team_membership, team:).user }
  let(:user) { create(:user) }

  describe '#can_view_request_details?' do
    context 'when user not on the team' do
      before do
        sign_in user
      end

      context 'a login.gov admin user' do
        let(:user) { create(:user, :logingov_admin) }

        it 'returns true' do
          expect(helper.can_view_request_details?(sp)).to be_truthy
        end
      end

      context 'when not a login.gov admin' do
        it 'returns false' do
          expect(helper.can_view_request_details?(sp)).to be_falsy
        end
      end
    end

    context 'a member of the team' do
      before do
        sign_in team_user
      end

      it 'returns true' do
        expect(helper.can_view_request_details?(sp)).to be_truthy
      end
    end
  end
end
