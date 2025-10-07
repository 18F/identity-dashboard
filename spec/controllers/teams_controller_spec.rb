require 'rails_helper'

describe TeamsController do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }
  let(:team) { create(:team) }
  let(:agency) { create(:agency) }
  let(:logger_double) { instance_double(EventLogger) }

  before do
    allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
    allow(controller).to receive(:current_user).and_return(user)
    allow(EventLogger).to receive(:new).and_return(logger_double)
    allow(logger_double).to receive(:team_created)
    allow(logger_double).to receive(:team_updated)
    allow(logger_double).to receive(:unauthorized_access_attempt)
    sign_in user
  end

  describe '#new' do
    context 'when the user is a login.gov admin' do
      let(:user) { create(:user, :logingov_admin) }

      it 'has a success response' do
        get :new
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the user is not an admin' do
      it 'has a success response' do
        get :new
        expect(response).to have_http_status(:ok)
      end

      context 'the user is not a fed' do
        before { user.update(email: 'user@example.com') }

        it 'has an error response' do
          get :new
          expect(response).to have_http_status(:unauthorized)
          expect(logger_double).to have_received(:unauthorized_access_attempt)
        end
      end
    end
  end

  describe '#index' do
    context 'when the user is signed in' do
      it 'has a success response' do
        get :index
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the user is not signed in' do
      before do
        allow(controller).to receive(:current_user).and_return(nil)
        sign_out user
      end

      it 'has a redirect response' do
        get :index
        expect(response).to have_http_status(:found)
      end
    end
  end

  describe '#show' do
    context 'when login.gov admin' do
      let(:user) { create(:user, :logingov_admin) }

      it 'shows the team template' do
        get :show, params: { id: team.id }
        expect(response).to render_template(:show)
      end

      it 'shows audit events' do
        test_version = PaperTrail::Version.new(
          object_changes: { 'user_email' => [nil, "test#{rand(1..1000)}@gsa.gov"] },
          created_at: 1.minute.ago,
          whodunnit: 'admin@login.gsa.gov',
          event: 'create',
          item_type: 'TeamMembership',
        )

        expect(TeamAuditEvent).to receive(:by_team).
          with(
            team,
            scope: PaperTrail::VersionPolicy::Scope.new(user, PaperTrail::Version).resolve,
          ).and_return([test_version])

        get :show, params: { id: team.id }

        expect(assigns[:audit_events][0].whodunnit).to eq(test_version.whodunnit)
        expect(assigns[:audit_events][0].created_at).to eq(test_version.created_at)
      end
    end

    context 'when a team member not login.gov admin' do
      before do
        team.users << user
      end

      it 'shows the team template' do
        get :show, params: { id: team.id }
        expect(response).to render_template(:show)
      end

      it 'does not show the paper trail' do
        no_versions = PaperTrail::Version.none
        no_versions_sql = no_versions.to_sql

        expect(TeamAuditEvent).to receive(:by_team).with(
          team,
          scope: have_attributes(to_sql: a_string_starting_with(no_versions_sql)),
        ).and_return(no_versions)
        get :show, params: { id: team.id }
        expect(assigns[:audit_events]).to eq([])
      end
    end
  end

  describe '#create' do
    context 'when not a login.gov admin' do
      let(:name) { 'unique name' }

      context 'and no fed email address' do
        before do
          user.update(email: 'user@example.com')
          post :create, params: { team: { name: name, agency_id: agency.id } }
        end

        it 'returns a 401' do
          expect(response).to have_http_status(:unauthorized)
          expect(logger_double).to have_received(:unauthorized_access_attempt)
        end

        it 'does not create the team' do
          team = Team.find_by(name:)
          expect(team).to be_nil
        end
      end

      context 'has a government email address' do
        let(:team) { Team.find_by(name: 'unique name') }

        before do
          post :create, params: { team: { name: name, agency_id: agency.id } }
        end

        it 'creates the team' do
          team_membership = TeamMembership.find_by(group_id: team.id,
                                                   user_id: user.id)

          expect(team).to_not be_nil
          expect(team.users).to eq([user])
          expect(team_membership.role).to eq(Role.find_by(name: 'partner_admin'))
        end

        # rubocop:disable Layout/LineLength
        it 'assigns a UUID to the team' do
          expect(team.uuid).to_not be_nil
          expect(team.uuid).to match(/[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[0-9a-f]{4}-[0-9a-f]{12}/)
        end
        # rubocop:enable Layout/LineLength

        it 'redirects' do
          expect(response).to redirect_to(team_users_path(team))
        end

        it 'logs' do
          changes = {
            'agency_id' => { 'old' => nil, 'new' => agency.id },
            'id' => team.id,
            'name' => { 'old' => nil, 'new' => team.name },
            'uuid' => { 'old' => nil, 'new' => team.uuid },
          }

          expect(logger_double).to have_received(:team_created).with(
            changes: hash_including(changes),
          )
        end
      end
    end

    context 'when a login.gov admin' do
      let(:user) { create(:user, :logingov_admin) }

      # rubocop:disable Layout/LineLength
      context 'when it creates successfully' do
        it 'has a redirect response' do
          post :create, params: { team: { name: 'unique name', agency_id: agency.id } }

          team = Team.find_by(name: 'unique name')

          expect(team).to_not be_nil
          expect(team.uuid).to match(/[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[0-9a-f]{4}-[0-9a-f]{12}/)
          expect(team.users).to eq([])
          expect(response).to redirect_to(team_users_path(team))
        end
      end
      # rubocop:enable Layout/LineLength

      context 'when it fails to create' do
        it 'renders #new' do
          post :create, params: { team: { name: '' } }
          expect(response).to render_template(:new)
        end
      end
    end
  end

  describe '#destroy' do
    context 'when a login.gov admin' do
      let(:user) { create(:user, :logingov_admin) }

      before do
        allow(logger_double).to receive(:team_destroyed)
        delete :destroy, params: { id: team.id }
      end

      it 'has a redirect response' do
        expect(response).to have_http_status(:found)
      end

      it 'logs' do
        changes = team.attributes.except('updated_at', 'created_at')
        expect(logger_double).to have_received(:team_destroyed).with(
          changes: hash_including(changes),
        )
      end
    end

    context 'when the user is not an admin' do
      it 'has an error response' do
        delete :destroy, params: { id: team.id }
        expect(response).to have_http_status(:unauthorized)
        expect(logger_double).to have_received(:unauthorized_access_attempt)
      end
    end
  end

  describe '#edit' do
    context 'when login.gov admin' do
      let(:user) { create(:user, :logingov_admin) }

      it 'shows the edit template' do
        get :edit, params: { id: team.id }
        expect(response).to render_template(:edit)
      end
    end

    context 'when not an admin but a team member' do
      before do
        team.users << user
      end

      it 'shows the edit template' do
        get :edit, params: { id: team.id }
        expect(response).to render_template(:edit)
      end
    end
  end

  describe '#update' do
    context 'when login.gov admin' do
      let(:user) { create(:user, :logingov_admin) }
      let(:team) { create(:team, description: 'original description') }
      let(:description) { 'a new description' }

      context 'when the update is successful' do
        before do
          patch :update, params: { id: team.id, team: { name: team.name, description: } }
        end
        it 'has a redirect response' do
          expect(response).to have_http_status(:found)
        end

        it 'logs' do
          changes = {
            'description' => { 'old' => 'original description', 'new' => description },
            'id' => team.id,
          }
          expect(logger_double).to have_received(:team_updated).with(
            changes:,
          )
        end

        context 'when no update is made' do
          let(:user1)  { create(:team_member, teams: [team]) }
          let(:user2)  { create(:team_member, teams: [team]) }

          before do
            team.update(users: [user, user1, user2])
          end

          it 'has the same number of users after' do
            expect(team.users.count).to eq 3
            patch :update, params: {
              id: team.id,
              team: { name: team.name, agency_id: team.agency_id, description: team.description },
            }
            expect(team.users.count).to eq 3
          end
        end
      end

      context 'when the update is unsuccessful' do
        before do
          allow_any_instance_of(Team).to receive(:update).and_return(false)
        end

        it 'renders the edit action' do
          patch :update, params: {
            id: team.id, team: { name: team.name }, new_user: { email: '' }
          }
          expect(response).to render_template(:edit)
        end
      end
    end

    context 'when user is not login.gov admin but a member of the team' do
      before do
        team.users << user
      end

      context 'when no update is made' do
        let(:user1)  { create(:team_member, teams: [team]) }
        let(:user2)  { create(:team_member, teams: [team]) }

        before do
          team.update(users: [user, user1, user2])
        end

        it 'has the same number of users after' do
          expect(team.users.count).to eq 3
          patch :update, params: {
            id: team.id,
            team: {
              name: team.name,
              agency_id: team.agency_id,
              description: team.description,
            },
            user_ids: "#{user.id} #{user1.id} #{user2.id}",
          }
          expect(team.users.count).to eq 3
        end
      end
    end

    context 'when user is neither a login.gov admin nor a team member' do
      it 'has an unauthorized response' do
        patch :update, params: {
          id: team.id,
          team: {
            name: team.name,
            agency_id: team.agency_id,
            description: team.description,
          },
        }
        expect(response).to have_http_status(:unauthorized)
        expect(logger_double).to have_received(:unauthorized_access_attempt)
      end
    end
  end
end
