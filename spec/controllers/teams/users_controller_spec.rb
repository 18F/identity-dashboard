require 'rails_helper'

describe Teams::UsersController do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }
  let(:team) { create(:team) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    sign_in user
  end

  describe '#remove_confirm' do
    let(:user_to_delete) { create(:user) }

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
        expect(response).to render_template(:delete)
      end
    end

    context 'when the user is part of the team but not the user to delete' do
        it 'renders an error' do
          team.users << user
          get :remove_confirm, params: { team_id: team.id, id: user_to_delete.id }
          expect(response.status).to eq(401)
        end
      end

    context 'when the user is an admin and user to delete is part of the team' do
      it 'renders the delete confirmation page' do
        user.admin = true
        team.users << user_to_delete
        get :remove_confirm, params: { team_id: team.id, id: user_to_delete.id }
        expect(response.status).to eq(200)
        expect(response).to render_template(:delete)
      end
    end
  end

  describe '#destroy' do
    let(:user_to_delete) { create(:user) }

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

    context 'when user not an admin but is a team member and user to delete is team member' do
        before do
            team.users << user_to_delete
            team.users << user
            delete :destroy, params: { team_id: team.id, id: user_to_delete.id }
        end

        it 'has a redirect response' do
            expect(response.status).to eq(302)
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
 end
end

