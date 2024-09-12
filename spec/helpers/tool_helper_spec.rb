require 'rails_helper'
describe TeamHelper do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }
  let(:sp) { create(:service_provider) }
  let(:team) { sp.team }

  before do
    sign_in user
  end

  describe '#can_view_request_details?' do
    context 'an admin user' do
      before do
        user.update(admin: true)
      end

      it 'returns true' do
        expect(helper.can_view_request_details?(sp)).to be true
      end
    end

    context 'a non-admin user' do
      it 'returns false' do
        expect(helper.can_view_request_details?(sp)).to be false
      end

      context 'a member of the team' do
        before do
          team.users << user
        end

        it 'returns true' do
          expect(helper.can_view_request_details?(sp)).to be true
        end
      end
    end
  end

end
