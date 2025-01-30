require 'rails_helper'

describe UsersController do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe '#new' do
    context 'when the user is an admin' do
      before do
        user.admin = true
      end

      it 'has a success response' do
        get :new
        expect(response.status).to eq(200)
      end
    end

    context 'when the user is not an admin' do
      it 'has an error response' do
        get :new
        expect(response.status).to eq(401)
      end
    end
  end

  describe '#index' do
    context 'when the user is an admin' do
      before do
        user.admin = true
      end

      it 'has a success response' do
        get :index
        expect(response.status).to eq(200)
      end
    end

    context 'when the user is not an admin' do
      it 'has an error response' do
        get :index
        expect(response.status).to eq(401)
      end
    end
  end

  describe '#edit' do
    context 'when the user is an admin' do
      before do
        user.admin = true
      end

      it 'has a success response' do
        get :edit, params: { id: user.id }
        expect(response.status).to eq(200)
      end

      context 'when editing a user without a team' do
        let(:editing_user) { build(:user) }

        it 'defaults to the site admin role for admins' do
          editing_user.admin = true
          editing_user.save!
          get :edit, params: { id: editing_user.id }
          expect(assigns['user_team'].role_name).to eq(Role::SITE_ADMIN.name)
        end

        it 'defaults to the admin role for admins' do
          editing_user.admin = false
          editing_user.save!
          get :edit, params: { id: editing_user.id }
          expect(assigns['user_team'].role_name).to eq('partner_admin')
        end
      end
    end

    context 'when the user is not an admin' do
      it 'has an error response' do
        get :edit, params: { id: 1 }
        expect(response.status).to eq(401)
      end
    end
  end

  describe '#update' do
    context 'when the user is an admin' do
      before do
        user.admin = true
      end

      it 'has a redirect response' do
        patch :update, params: { id: user.id, user: { admin: true, email: 'example@example.com' } }
        expect(response.status).to eq(302)
      end

      it 'assigns a new role to all teams' do
        user_to_edit = create(:user, :with_teams)
        user_to_edit.user_teams.each do |ut|
          expect(ut.role_name).to be_nil
        end
        patch :update, params: { id: user_to_edit, user: {
          user_team: { role_name: 'partner_admin' },
        } }
        user_to_edit.reload
        user_to_edit.user_teams.each do |ut|
          expect(ut.role_name).to eq('partner_admin')
        end
      end
    end

    context 'when the user is not an admin' do
      it 'has an error response' do
        patch :update, params: { id: user.id, user: { admin: true, email: 'example@example.com' } }
        expect(response.status).to eq(401)
      end
    end
  end

  describe '#create' do
    context 'when the user is an admin' do
      before do
        user.admin = true
      end

      context 'when the user is valid' do
        it 'has a redirect response' do
          patch :create, params: { user: { admin: true, email: 'example@example.com' } }
          expect(response.status).to eq(302)
        end
      end

      context 'when the user is invalid' do
        it "renders the 'new' view" do
          patch :create, params: { user: { admin: true, email: user.email } }
          expect(response).to render_template(:new)
        end
      end
    end

    context 'when the user is not an admin' do
      it 'has an error response' do
        patch :create, params: { user: { admin: true, email: 'example@example.com' } }
        expect(response.status).to eq(401)
      end
    end
  end

  describe '#destroy' do
    let(:user_to_delete) { create(:user) }

    context 'when the user is an admin' do
      before do
        user.admin = true
        delete :destroy, params: { id: user_to_delete.id }
      end

      it 'has a redirect response' do
        expect(response.status).to eq(302)
      end
    end

    context 'when the user is not an admin'
    it 'has an error response' do
      delete :destroy, params: { id: user_to_delete.id }
      expect(response.status).to eq(401)
    end
  end
end
