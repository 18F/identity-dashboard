require 'rails_helper'

describe ManageUsersController do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }
  let(:team) { create(:team) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    sign_in user
  end

  describe '#new' do
    context 'when user is not part of the team' do
      it 'renders an error' do
        get :new, params: { team_id: team.id }
        expect(response.status).to eq(401)
      end
    end

    context 'when the user is part of the team' do
      it 'renders the manage users form' do
        team.users << user
        get :new, params: { team_id: team.id }
        expect(response.status).to eq(200)
        expect(response).to render_template(:new)
      end
    end

    context 'when the user is an admin' do
      it 'renders the manage users form' do
        user.admin = true
        get :new, params: { team_id: team.id }
        expect(response.status).to eq(200)
        expect(response).to render_template(:new)
      end
    end
  end

  describe '#create' do
    let(:user_emails) { ['user1@gsa.gov', 'user2@gsa.gov'] }

    context 'when the user is not part of the team' do
      it 'renders an error' do
        post :create, params: { team_id: team.id, user_emails: user_emails }
        expect(response.status).to eq(401)
      end
    end

    context 'when ther user is part of the team' do
      it 'saves valid info' do
        team.users << user
        post :create, params: { team_id: team.id, user_emails: user_emails }

        expect(response).to redirect_to(team_path(team))

        saved_user_emails = team.reload.users.map(&:email)

        expect(saved_user_emails).to include('user1@gsa.gov')
        expect(saved_user_emails).to include('user2@gsa.gov')
      end

      it 'does not save invalid info and renders an error' do
        team.users << user
        post :create, params: { team_id: team.id, user_emails: user_emails + ['invalid'] }

        expect(response).to render_template(:new)

        saved_user_emails = team.reload.users.map(&:email)

        expect(saved_user_emails).to_not include('user1@gsa.gov')
        expect(saved_user_emails).to_not include('user2@gsa.gov')
        expect(saved_user_emails).to_not include('invalid')
      end
    end

    context 'when the user is an admin' do
      it 'saves valid info' do
        team.users << user
        post :create, params: { team_id: team.id, user_emails: user_emails }

        expect(response).to redirect_to(team_path(team))

        saved_user_emails = team.reload.users.map(&:email)

        expect(saved_user_emails).to include('user1@gsa.gov')
        expect(saved_user_emails).to include('user2@gsa.gov')
      end

      it 'does not save invalid info and renders an error' do
        team.users << user
        post :create, params: { team_id: team.id, user_emails: user_emails + ['invalid'] }

        expect(response).to render_template(:new)

        saved_user_emails = team.reload.users.map(&:email)

        expect(saved_user_emails).to_not include('user1@gsa.gov')
        expect(saved_user_emails).to_not include('user2@gsa.gov')
        expect(saved_user_emails).to_not include('invalid')
      end
    end
  end
end
