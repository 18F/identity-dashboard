require 'rails_helper'

RSpec.describe SecurityEventsController do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    sign_in(user)

    2.times do
      create(:security_event, user: user)
    end
    create(:security_event, user: other_user)
  end

  describe '#index' do
    it 'renders security events for the current user only' do
      get :index

      security_events = assigns[:security_events]
      expect(security_events.size).to eq(2)
      expect(security_events.map(&:user).uniq).to eq([user])
    end

    it 'redirects to the first page from an invalid page' do
      get :index, params: { page: 1000 }

      expect(response).to redirect_to(security_events_path)
    end
  end

  describe '#all' do
    context 'for an admin user' do
      let(:user) { create(:admin) }

      it 'renders security events for all users' do
        get :all

        security_events = assigns[:security_events]
        expect(security_events.size).to eq(3)
        expect(security_events.map(&:user).uniq).to match_array([user, other_user])
      end

      it 'redirects to the first page from an invalid page' do
        get :all, params: { page: 1000 }

        expect(response).to redirect_to(security_events_all_path)
      end
    end

    context 'for a non-admin user' do
      it 'renders an error' do
        get :all

        expect(response).to be_unauthorized
      end
    end
  end
end
