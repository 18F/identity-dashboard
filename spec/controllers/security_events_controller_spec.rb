require 'rails_helper'

RSpec.describe SecurityEventsController do
  let(:user) { create(:user, uuid: SecureRandom.uuid) }
  let(:other_user) { create(:user, uuid: SecureRandom.uuid) }

  before do
    sign_in(user)

    2.times do
      create(:security_event, user:)
    end
    create(:security_event, user: other_user)
  end

  describe '#index' do
    context 'when not a login.gov admin' do
      let(:user) { other_user }

      it 'renders unauthorized' do
        get :index
        expect(user.admin).to be false
        expect(response).to be_unauthorized
      end
    end

    let(:user) { create(:logingov_admin) }

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
    context 'when a login.gov admin' do
      let(:user) { create(:logingov_admin) }

      it 'renders security events for all users' do
        get :all

        security_events = assigns[:security_events]
        expect(security_events.size).to eq(3)
        expect(security_events.map(&:user).uniq).to contain_exactly(user, other_user)
      end

      it 'filters by user with a user_uuid param' do
        get :all, params: { user_uuid: other_user.uuid }

        expect(assigns[:user]).to eq(other_user)

        security_events = assigns[:security_events]
        expect(security_events.size).to eq(1)
        expect(security_events.map(&:user_id).uniq).to eq([other_user.id])
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

    context 'when a login.gov admin' do
      it 'renders an error' do
        get :all

        expect(response).to be_unauthorized
      end
    end
  end

  describe '#show' do
    subject(:action) { get :show, params: { id: } }

    let(:security_event) { create(:security_event, user:) }
    let(:id) { security_event.id }

    context 'for an event belonging to the current user' do
      let(:security_event) { create(:security_event, user:) }

      it 'renders the event' do
        action
        expect(assigns[:security_event]).to eq(security_event)
      end
    end

    context 'for an event belonging to a different user' do
      let(:security_event) { create(:security_event, user: build(:user)) }

      it 'renders an error' do
        action

        expect(response).to be_unauthorized
      end

      context 'when the current user is a login.gov admin' do
        let(:user) { create(:logingov_admin) }

        it 'renders the event' do
          action
          expect(assigns[:security_event]).to eq(security_event)
        end
      end
    end

    context 'for an event that does not exist' do
      let(:id) { 'abcdef' }

      it '404s' do
        action

        expect(response).to be_not_found
      end
    end
  end

  describe '#search' do
    context 'when not login.gov admin' do
      it 'renders an error' do
        post :search

        expect(response).to be_unauthorized
      end
    end

    context 'when a login.gov admin' do
      let(:user) { create(:logingov_admin) }

      context 'with an email that belongs to a user' do
        it 'redirects back to all with the UUID in the params' do
          post :search, params: { email: other_user.email }

          expect(response).to redirect_to(security_events_all_path(user_uuid: other_user.uuid))
        end
      end

      context 'with an email that does not belong to a user' do
        it 'redirects back to all and shows a warning flash' do
          post :search, params: { email: 'some-fake-email' }

          expect(response).to redirect_to(security_events_all_path)
          expect(flash[:warning]).to include('Could not find a user with email some-fake-email')
        end
      end

      context 'without any params' do
        it 'redirects back to all' do
          post :search
          expect(response).to redirect_to(security_events_all_path)
        end
      end
    end
  end
end
