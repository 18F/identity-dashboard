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

    context 'with no events' do
      before { SecurityEvent.delete_all }

      it 'renders an empty page' do
        get :index

        expect(assigns[:security_events].size).to eq(0)
        expect(response).to be_ok
      end
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

      context 'with no events' do
        before { SecurityEvent.delete_all }

        it 'renders an empty page' do
          get :index

          expect(assigns[:security_events].size).to eq(0)
          expect(response).to be_ok
        end
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
