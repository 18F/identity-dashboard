require 'rails_helper'

describe Teams::UsersController do
  include Devise::Test::ControllerHelpers
  let(:user) { team_membership.user }
  let(:team) { team_membership.team }
  let(:user_to_delete) { create(:team_membership, team:).user }
  let(:valid_email) { 'user1@gsa.gov' }
  let(:invalid_email) { 'invalid' }
  let(:logger_double) { instance_double(EventLogger) }

  shared_examples_for 'can create valid users' do
    it 'saves valid info' do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
      post :create, params: { team_id: team.id, user: { email: valid_email } }

      expect(response).to redirect_to(new_team_user_path(team))
      saved_user_emails = team.reload.users.map(&:email)
      expect(saved_user_emails).to include(valid_email)
    end

    it 'does not save invalid info' do
      post :create, params: { team_id: team.id, user: { email: invalid_email } }

      saved_user_emails = team.reload.users.map(&:email)
      expect(saved_user_emails).to_not include(invalid_email)
    end
  end

  shared_examples_for 'destroys user' do
    it 'removes the user' do
      expect(team.users).to include(user_to_delete)
      expect do
        post :destroy, params: { team_id: team.id, id: user_to_delete.id }
      end.to change { TeamMembership.count }.by(-1)
      expect(team.users).to_not include(user_to_delete)
    end
  end

  shared_examples_for 'cannot destroy user' do
    it 'is not allowed' do
      expect(team.users).to include(user_to_delete)
      expect do
        post :destroy, params: { team_id: team.id, id: user_to_delete.id }
      end.to_not(change { TeamMembership.count })
      expect(team.users.reload).to include(user_to_delete)
      expect(response).to be_unauthorized
    end
  end

  context 'when logged in' do
    before do
      sign_in user
      allow(logger_double).to receive(:unauthorized_access_attempt)
      allow(EventLogger).to receive(:new).and_return(logger_double)
    end

    context 'with Partner Admin role' do
      let(:team_membership) { create(:team_membership, :partner_admin) }

      describe '#index' do
        it 'returns OK with the expected template' do
          get :index, params: { team_id: team.id }
          expect(response).to be_ok
          expect(response).to render_template(:index)
        end
      end

      describe '#new' do
        it 'returns OK with the expected template' do
          get :new, params: { team_id: team.id }
          expect(response).to be_ok
          expect(response).to render_template(:new)
        end
      end

      describe '#create' do
        before { allow(logger_double).to receive(:team_membership_created) }
        it_behaves_like 'can create valid users'

        context 'logging' do
          it 'calls log.team_membership_created' do
            post :create, params: { team_id: team.id, user: { email: valid_email } }
            membership = TeamMembership.find_by(user: User.find_by(email: valid_email), team:)
            changes = membership.attributes.except('created_at', 'updated_at').merge(
              'team_user' => membership.user.email,
              'team' => membership.team.name,
            )

            expect(logger_double).to have_received(:team_membership_created).with(
              changes: hash_including(changes),
            )
          end
        end
      end

      describe '#update' do
        let(:updatable_team_membership) { create(:team_membership, :partner_developer, team:) }

        before { allow(logger_double).to receive(:team_membership_updated) }

        it 'allows valid roles' do
          put :update, params: {
            team_id: team.id,
            id: updatable_team_membership.user.id,
            team_membership: { role_name: 'partner_readonly' },
          }
          updatable_team_membership.reload
          expect(updatable_team_membership.role.name).to eq('partner_readonly')
        end

        it 'does not accept invalid roles' do
          put :update, params: {
            team_id: team.id,
            id: updatable_team_membership.user.id,
            team_membership: { role_name: 'totally-fake-role' },
          }
          expect(response).to be_unauthorized
          updatable_team_membership.reload
          expect(updatable_team_membership.role.friendly_name).to eq('Partner Developer')

          expect(logger_double).to_not have_received(:team_membership_updated)
        end

        it 'redirects without RBAC flag' do
          allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
          put :update, params: {
            team_id: team.id,
            id: updatable_team_membership.user.id,
            team_membership: { role_name: 'totally-fake-role' },
          }
          expect(response).to redirect_to(team_users_path(team))
          expect(logger_double).to_not have_received(:team_membership_updated)
        end

        it 'is unauthorized if the policy role list is empty' do
          policy_double = TeamMembershipPolicy.new(user, updatable_team_membership)
          expect(policy_double).to receive(:roles_for_edit).and_return([]).at_least(:once)
          allow(TeamMembershipPolicy).to receive(:new).and_return(policy_double)
          put :update, params: {
            team_id: team.id,
            id: updatable_team_membership.user.id,
            team_membership: { role_name: Role.last.name },
          }
          expect(response).to be_unauthorized
          expect(logger_double).to_not have_received(:team_membership_updated)
        end

        context 'logging' do
          let(:updatable_team_membership) { create(:team_membership, :partner_readonly, team:) }

          it 'logs updates to team member roles' do
            put :update, params: {
              team_id: team.id,
              id: updatable_team_membership.user.id,
              team_membership: { role_name: 'partner_developer' },
            }

            changes = {
              'role_name' => { 'old' => 'partner_readonly', 'new' => 'partner_developer' },
              'id' => updatable_team_membership.id,
              'team_user' => updatable_team_membership.user.email,
              'team' => updatable_team_membership.team.name,
            }

            expect(logger_double).to have_received(:team_membership_updated).with(
              changes:,
            )
          end

          it 'does not log updates when roles are unchanged' do
            put :update, params: {
              team_id: team.id,
              id: updatable_team_membership.user.id,
              team_membership: { role_name: 'partner_readonly' },
            }

            expect(logger_double).to_not have_received(:team_membership_updated)
          end
        end
      end

      describe '#edit' do
        it 'redirects without RBAC flag' do
          allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
          get :edit, params: {
            team_id: team.id,
            id: user,
          }
          expect(response).to redirect_to(team_users_path(team))
        end
      end

      describe '#remove_confirm' do
        it 'is allowed for others' do
          get :remove_confirm, params: { team_id: team.id, id: user_to_delete.id }
          expect(response).to be_ok
          expect(response).to render_template(:remove_confirm)
        end

        it 'is not allowed for self' do
          get :remove_confirm, params: { team_id: team.id, id: user.id }
          # If unauthorized, the option to delete should not show up in the UI
          # so it is acceptable to show "unauthorized" instead of a redirect
          expect(response).to be_unauthorized
          expect(response).to_not render_template(:remove_confirm)
          expect(logger_double).to have_received(:unauthorized_access_attempt)
        end
      end

      describe '#destroy' do
        before { allow(logger_double).to receive(:team_membership_destroyed) }
        it_behaves_like 'destroys user'

        context 'when a user attempts to destroy themselves' do
          let(:user_to_delete) { user }

          it_behaves_like 'cannot destroy user'

          it 'does not log an event' do
            post :destroy, params: { team_id: team.id, id: user_to_delete.id }
            expect(logger_double).to_not have_received(:team_membership_destroyed)
          end
        end

        context 'logging' do
          it 'calls log.team_membership_destroyed' do
            team_membership = TeamMembership.find_by(user: user_to_delete, team:)
            post :destroy, params: { team_id: team.id, id: user_to_delete.id }

            changes = team_membership.attributes.except('created_at', 'updated_at').merge(
              'team_user' => user_to_delete.email,
              'team' => team_membership.team.name,
            )

            expect(logger_double).to have_received(:team_membership_destroyed).with(
              changes: hash_including(changes),
            )
          end
        end
      end
    end

    context 'with Partner Developer role' do
      let(:team_membership) { create(:team_membership, :partner_developer) }

      describe '#index' do
        it 'returns OK with the expected template' do
          get :index, params: { team_id: team.id }
          expect(response).to be_ok
          expect(response).to render_template(:index)
        end
      end

      describe '#new' do
        it 'is not allowed' do
          get :new, params: { team_id: team.id }
          expect(response).to be_unauthorized
          expect(logger_double).to have_received(:unauthorized_access_attempt)
        end
      end

      describe '#create' do
        it 'is not allowed' do
          post :create, params: { team_id: team.id, user: { email: valid_email } }
          expect(response).to be_unauthorized
          expect(logger_double).to have_received(:unauthorized_access_attempt)
        end
      end

      describe '#remove_confirm' do
        it 'is not allowed' do
          get :remove_confirm, params: { team_id: team.id, id: user_to_delete.id }
          expect(response).to be_unauthorized
          expect(logger_double).to have_received(:unauthorized_access_attempt)
        end
      end

      describe '#destroy' do
        it_behaves_like 'cannot destroy user'
      end
    end

    context 'with Partner Readonly role' do
      let(:team_membership) { create(:team_membership, :partner_readonly) }
      let(:user_to_change) { create(:team_membership, team:).user }

      describe '#index' do
        it 'is not allowed' do
          get :index, params: { team_id: team.id }
          expect(response).to be_unauthorized
        end
      end

      describe '#new' do
        it 'is not allowed' do
          get :new, params: { team_id: team.id }
          expect(response).to be_unauthorized
        end
      end

      describe '#edit' do
        before do
          token_response =
            {
              'access_token' => 'mock_access_token',
              'expires_in' => 3600,
              'refresh_token' => 'mock_refresh_token',
              'refresh_expires_in' => 7200,
            }.to_json

          stub_request(:post, 'https://airtable.com/oauth2/v1/token').
            with(
              body: { 'grant_type' => 'refresh_token',
'redirect_uri' => 'http://test.host/airtable/oauth/redirect', 'refresh_token' => nil },
              headers: {
                'Accept' => '*/*',
             'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
             'Authorization' => 'Basic Og==',
             'Content-Type' => 'application/x-www-form-urlencoded',
             'User-Agent' => 'Ruby',
              },
            ).
            to_return(status: 200, body: token_response, headers: {})
        end

        it 'is not allowed' do
          get :edit, params: { team_id: team.id, id: user_to_change.id }
          expect(response).to be_unauthorized
        end
      end

      describe '#create' do
        it 'is not allowed' do
          post :create, params: {
            team_id: team.id,
            id: user_to_change.id,
            user: { email: build(:user).email },
          }
          expect(response).to be_unauthorized
        end
      end

      describe '#update' do
        it 'is not allowed' do
          post :update, params: {
            team_id: team.id,
            id: user_to_change.id,
            team_membership: { role_name: 'partner_readonly' },
          }
          expect(response).to be_unauthorized
        end
      end

      describe '#remove_confirm' do
        it 'is not allowed' do
          get :remove_confirm, params: { team_id: team.id, id: user_to_delete.id }
          expect(response).to be_unauthorized
        end
      end

      describe '#destroy' do
        it_behaves_like 'cannot destroy user'
      end
    end

    context 'as login.gov admin' do
      let(:team_membership) { create(:team_membership) }

      before do
        user.admin = true
        user.save!
        TeamMembership.find_or_build_logingov_admin(user).save!
      end

      describe '#remove_confirm' do
        it 'is allowed for others' do
          get :remove_confirm, params: { team_id: team.id, id: user_to_delete.id }
          expect(response).to be_ok
          expect(response).to render_template(:remove_confirm)
        end

        # TeamMembership in this team does not determin login.gov admin rights
        # so a login.gov admin is safe to remove themself from this team.
        it 'is allowed for self' do
          get :remove_confirm, params: { team_id: team.id, id: user.id }
          expect(response).to be_ok
          expect(response).to render_template(:remove_confirm)
        end
      end

      describe '#destroy' do
        before { allow(logger_double).to receive(:team_membership_destroyed) }
        it_behaves_like 'destroys user'

        context 'for self' do
          let(:user_to_delete) { user }

          # TeamMembership in this team does not determine login.gov admin rights
          # so a login.gov admin is safe to remove themself from this team.
          it_behaves_like 'destroys user'
        end
      end
    end
  end
end
