require 'rails_helper'

describe UsersController do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }
  let(:logger_double) { instance_double(EventLogger) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(logger_double).to receive(:user_created)
    allow(logger_double).to receive(:unauthorized_access_attempt)
    allow(EventLogger).to receive(:new).and_return(logger_double)
  end

  describe '#new' do
    context 'when a login.gov admin' do
      let(:user) { create(:user, :logingov_admin) }

      it 'has a success response' do
        get :new
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when not a login.gov admin' do
      it 'has an error response' do
        get :new
        expect(response).to have_http_status(:unauthorized)
        expect(logger_double).to have_received(:unauthorized_access_attempt)
      end
    end
  end

  describe '#index' do
    context 'when a login.gov admin' do
      let(:user) { create(:user, :logingov_admin) }

      it 'has a success response' do
        get :index
        expect(response).to have_http_status(:ok)
      end

      describe 'pagination' do
        let!(:users) { create_list(:user, 150) }

        it 'sets pagination variables' do
          get :index
          expect(assigns(:page)).to eq(1)
          expect(assigns(:total_count)).to eq(User.count)
          expect(assigns(:total_pages)).to eq(
            (User.count.to_f / IdentityConfig.store.users_per_page).ceil,
          )
        end

        it 'defaults to page 1' do
          get :index
          expect(assigns(:page)).to eq(1)
          expect(assigns(:users).size).to be <= IdentityConfig.store.users_per_page
        end

        it 'returns the correct page when page param is provided' do
          get :index, params: { page: 2 }
          expect(assigns(:page)).to eq(2)
        end

        it 'limits results to PER_PAGE' do
          get :index
          expect(assigns(:users).size).to eq(IdentityConfig.store.users_per_page)
        end

        it 'returns remaining users on last page' do
          total_pages = (User.count.to_f / IdentityConfig.store.users_per_page).ceil
          get :index, params: { page: total_pages }
          expected_count = User.count % IdentityConfig.store.users_per_page
          expected_count = IdentityConfig.store.users_per_page if expected_count == 0
          expect(assigns(:users).size).to eq(expected_count)
        end

        it 'treats page 0 as page 1' do
          get :index, params: { page: 0 }
          expect(assigns(:page)).to eq(1)
        end

        it 'treats negative page numbers as page 1' do
          get :index, params: { page: -5 }
          expect(assigns(:page)).to eq(1)
        end

        it 'clamps page number to last page if too high' do
          get :index, params: { page: 9999 }
          expect(assigns(:page)).to eq(assigns(:total_pages))
        end

        it 'eager loads team_memberships with roles and teams' do
          get :index
          # Verify no N+1 queries by checking associations are loaded
          assigns(:users).each do |u|
            expect(u.team_memberships.loaded?).to be(true)
          end
        end
      end
    end

    context 'when not a login.gov admin' do
      it 'has an error response' do
        get :index
        expect(response).to have_http_status(:unauthorized)
        expect(logger_double).to have_received(:unauthorized_access_attempt)
      end
    end
  end

  describe '#edit' do
    context 'when a login.gov admin' do
      let(:user) { create(:user, :logingov_admin) }

      it 'has a success response' do
        get :edit, params: { id: user.id }
        expect(response).to have_http_status(:ok)
      end

      context 'when editing a user without a team' do
        let(:editing_user) { build(:user) }

        it 'defaults to the login.gov admin role for login.gov admins' do
          editing_user = create(:user, :logingov_admin)
          get :edit, params: { id: editing_user.id }
          expect(assigns['team_membership'].role_name).to eq(Role::LOGINGOV_ADMIN.name)
        end

        it 'defaults to the partner admin role for non-login.gov admins' do
          editing_user.save!
          get :edit, params: { id: editing_user.id }
          expect(assigns['team_membership'].role_name).to eq('partner_admin')
        end
      end
    end

    context 'when not a login.gov admin' do
      it 'has an error response' do
        get :edit, params: { id: 1 }
        expect(response).to have_http_status(:unauthorized)
        expect(logger_double).to have_received(:unauthorized_access_attempt)
      end
    end
  end

  describe '#update' do
    context 'when the user is a login.gov admin' do
      let(:user) { create(:user, :logingov_admin) }

      before { allow(logger_double).to receive(:team_membership_updated) }

      it 'has a redirect response' do
        patch :update, params: { id: user.id, user: { email: 'example@example.com' } }
        expect(response).to have_http_status(:found)
      end

      it 'assigns a new role to all teams' do
        user_to_edit = create(:user, :with_teams)
        user_to_edit.team_memberships.each do |ut|
          expect(ut.role_name).to be_nil
        end
        patch :update, params: { id: user_to_edit, user: {
          team_membership: { role_name: 'partner_admin' },
        } }
        user_to_edit.reload
        user_to_edit.team_memberships.each do |ut|
          expect(ut.role_name).to eq('partner_admin')
        end
      end

      context 'logging' do
        let(:updated_user) { create(:user, :team_member) }
        let(:new_role) { 'partner_readonly' }

        it 'logs updates to team member roles only' do
          expect(logger_double).to_not receive(:user_created)
          expect(logger_double).to_not receive(:user_destroyed)

          patch :update, params: { id: updated_user.id, user: {
            team_membership: { role_name: 'partner_readonly' },
          } }
          updated_user.reload

          changes = {
            'role_name' => {
              'old' => nil,
              'new' => new_role,
            },
              'id' => updated_user.team_memberships.first.id,
              'team_user' => updated_user.email,
              'team' => updated_user.team_memberships.first.team.name,
          }

          expect(logger_double).to have_received(:team_membership_updated).with(changes:)
        end

        context 'when the update is run with with no changes to membership' do
          let(:updated_user) { create(:user, :logingov_admin) }

          it 'does not log the update' do
            expect(logger_double).to_not receive(:user_created)
            expect(logger_double).to_not receive(:user_destroyed)

            patch :update, params: { id: updated_user.id, user: {
              team_membership: { role_name: updated_user.primary_role.name },
            } }

            updated_user.reload
            expect(logger_double).to_not have_received(:team_membership_updated)
          end
        end
      end
    end

    context 'when not a login.gov admin' do
      it 'has an error response' do
        patch :update, params: { id: user.id, user: { email: 'example@example.com' } }
        expect(response).to have_http_status(:unauthorized)
        expect(logger_double).to have_received(:unauthorized_access_attempt)
      end
    end
  end

  describe '#create' do
    context 'when the user is a login.gov admin' do
      let(:user) { create(:user, :logingov_admin) }

      context 'when the user is valid' do
        it 'has a redirect response' do
          patch :create, params: { user: { email: 'example@example.com' } }
          expect(response).to have_http_status(:found)
        end
      end

      context 'when the user is invalid' do
        it 'renders the #new view' do
          patch :create, params: { user: { email: user.email } }
          expect(response).to render_template(:new)
        end
      end

      context 'logging' do
        it 'calls log.user_created' do
          patch :create, params: { user: { email: 'example@example.com' } }
          user = User.find_by(email: 'example@example.com')
          changes = {
            'id' => user.id,
            'email' => {
              'old' => nil,
              'new' => 'example@example.com',
            },
          }

          expect(logger_double).to have_received(:user_created).with(
            changes: hash_including(changes),
          )
        end
      end
    end

    context 'when the user is not a login.gov admin' do
      it 'has an error response' do
        patch :create, params: { user: { email: 'example@example.com' } }
        expect(response).to have_http_status(:unauthorized)
        expect(logger_double).to have_received(:unauthorized_access_attempt)
      end
    end
  end

  describe '#destroy' do
    let(:user_to_delete) { create(:user) }

    context 'when a login.gov admin' do
      let(:user) { create(:user, :logingov_admin) }

      before do
        allow(logger_double).to receive(:user_destroyed)
        delete :destroy, params: { id: user_to_delete.id }
      end

      it 'has a redirect response' do
        expect(response).to have_http_status(:found)
      end

      context 'logging' do
        it 'calls log.user_destroyed' do
          expect(logger_double).to have_received(:user_destroyed).with(
            changes: user_to_delete.reload.as_json,
          )
        end
      end
    end

    context 'when not a login.gov admin' do
      it 'has an error response' do
        delete :destroy, params: { id: user_to_delete.id }
        expect(response).to have_http_status(:unauthorized)
        expect(logger_double).to have_received(:unauthorized_access_attempt)
      end
    end
  end

  describe '#none' do
    it 'works' do
      get :none
      expect(response).to have_http_status(:ok)
    end
  end
end
