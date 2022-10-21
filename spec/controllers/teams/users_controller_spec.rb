require 'rails_helper'

describe Teams::UsersController do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }
  let(:team) { create(:team) }
  let(:user_to_delete) { create(:user) }

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
    let(:user_email) { 'user1@gsa.gov' }

    context 'when the user is not part of the team' do
      it 'renders an error' do
        post :create, params: { team_id: team.id, user: { email: user_email } }
        expect(response.status).to eq(401)
      end
    end

    context 'when ther user is part of the team' do
      it 'saves valid info' do
        team.users << user
        post :create, params: { team_id: team.id, user: { email: user_email } }

        expect(response).to redirect_to(team_path(team))

        saved_user_emails = team.reload.users.map(&:email)

        expect(saved_user_emails).to include('user1@gsa.gov')
      end

      it 'does not save invalid info and renders an error' do
        team.users << user
        post :create, params: { team_id: team.id, user: { email: 'invalid' } }

        expect(response).to render_template(:new)

        saved_user_emails = team.reload.users.map(&:email)

        expect(saved_user_emails).to_not include('user1@gsa.gov')
        expect(saved_user_emails).to_not include('invalid')
      end
    end

    context 'when the user is an admin' do
      it 'saves valid info' do
        team.users << user
        post :create, params: { team_id: team.id, user: { email: user_email } }

        expect(response).to redirect_to(team_path(team))

        saved_user_emails = team.reload.users.map(&:email)

        expect(saved_user_emails).to include('user1@gsa.gov')
      end

      it 'does not save invalid info and renders an error' do
        team.users << user
        post :create, params: { team_id: team.id, user: { email: 'invalid' } }

        expect(response).to render_template(:new)

        saved_user_emails = team.reload.users.map(&:email)

        expect(saved_user_emails).to_not include('user1@gsa.gov')
        expect(saved_user_emails).to_not include('invalid')
      end
    end
  end

  describe '#remove_confirm' do

    context 'when user is not part of the team or an admin' do
      it 'renders an error' do
        get :remove_confirm, params: { team_id: team.id, id: user_to_delete.id }
        expect(response.status).to eq(401)
      end
    end

    context 'when the user and user to delete is part of the team' do
      it 'renders the delete confirmation page' do
        team.users << user
        team.users << user_to_delete
        get :remove_confirm, params: { team_id: team.id, id: user_to_delete.id }
        expect(response.status).to eq(200)
        expect(response).to render_template(:remove_confirm)
      end
    end

    context 'when the user is part of the team but not the user to delete' do
        it 'renders an error' do
          team.users << user
          get :remove_confirm, params: { team_id: team.id, id: user_to_delete.id }
          expect(response.status).to eq(401)
        end
      end

    context 'when the user belongs to team but tries to remove themselves from the team' do
        it 'renders an error' do
          team.users << user
          get :remove_confirm, params: { team_id: team.id, id: user.id }
          expect(response.status).to eq(401)
        end
    end

    context 'when the user is an admin and user to delete is part of the team' do
      it 'renders the delete confirmation page' do
        user.admin = true
        team.users << user_to_delete
        get :remove_confirm, params: { team_id: team.id, id: user_to_delete.id }
        expect(response.status).to eq(200)
        expect(response).to render_template(:remove_confirm)
      end
    end

    context 'when the user is not signed in' do
      before do
        allow(controller).to receive(:current_user).and_return(nil)
        sign_out user
      end

      it 'has a redirect response' do
        get :remove_confirm, params: { team_id: team.id, id: user_to_delete.id }
        expect(response.status).to eq(302)
      end
    end
  end

  describe '#destroy' do

    context 'when the user is an admin but not a team member and user to delete is team member' do
      before do
        user.admin = true
        team.users << user_to_delete
        delete :destroy, params: { team_id: team.id, id: user_to_delete.id }
      end

      it 'has a redirect response' do
        expect(response.status).to eq(302)
      end
    end

    context 'when user is a team member and user to delete is team member' do
        before do
            team.users << user_to_delete
            team.users << user
            delete :destroy, params: { team_id: team.id, id: user_to_delete.id }
        end

        it 'has a redirect response' do
            expect(response.status).to eq(302)
        end

        it 'user no longer in team' do
          deleted_user = team.users.find_by(id: user_to_delete.id)
          expect(deleted_user).to be_nil
      end
    end

    context 'when the user tries to remove themselves from the team' do
        it 'renders an error' do
          team.users << user
          get :remove_confirm, params: { team_id: team.id, id: user.id }
          expect(response.status).to eq(401)
        end
    end

    context 'when user not an admin but is a team member and user to delete is not team member' do
        before do
            team.users << user
            delete :destroy, params: { team_id: team.id, id: user_to_delete.id }
        end

        it 'has an error response' do
            expect(response.status).to eq(401)
        end
    end

    context 'when the user is not an admin or a team member' do
        it 'has an error response' do
            delete :destroy, params: { team_id: team.id, id: user_to_delete.id }
            expect(response.status).to eq(401)
        end
    end

    context 'when the user is not signed in' do
      before do
        allow(controller).to receive(:current_user).and_return(nil)
        sign_out user
      end

      it 'has a redirect response' do
        delete :destroy, params: { team_id: team.id, id: user_to_delete.id }
        expect(response.status).to eq(302)
      end
    end
 end
end

