require 'rails_helper'

describe TeamsController do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }
  let(:org) { create(:team) }
  let(:agency) { create(:agency) }

  before do
    allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
    allow(controller).to receive(:current_user).and_return(user)
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
        get :show, params: { id: org.id }
        expect(response).to render_template(:show)
      end

      it 'will show audit events' do
        test_version = PaperTrail::Version.new(
          object_changes: { 'user_email' => [nil, "test#{rand(1..1000)}@gsa.gov"] },
          created_at: 1.minute.ago,
          whodunnit: 'admin@login.gsa.gov',
          event: 'create',
          item_type: 'UserTeam',
        )

        expect(TeamAuditEvent).to receive(:by_team).
          with(
            org,
            scope: PaperTrail::VersionPolicy::Scope.new(user, PaperTrail::Version).resolve,
          ).and_return([test_version])

        get :show, params: { id: org.id }

        expect(assigns[:audit_events][0].whodunnit).to eq(test_version.whodunnit)
        expect(assigns[:audit_events][0].created_at).to eq(test_version.created_at)
      end
    end

    context 'when a team member not login.gov admin' do
      before do
        org.users << user
      end

      it 'shows the team template' do
        get :show, params: { id: org.id }
        expect(response).to render_template(:show)
      end

      it 'will not show the paper trail' do
        no_versions = PaperTrail::Version.none
        no_versions_sql = no_versions.to_sql

        expect(TeamAuditEvent).to receive(:by_team).with(
          org,
          scope: have_attributes(to_sql: a_string_starting_with(no_versions_sql)),
        ).and_return(no_versions)
        get :show, params: { id: org.id }
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
        end

        it 'does not create the team' do
          team = Team.find_by(name:)
          expect(team).to be_nil
        end
      end

      context 'has a government email address' do
        before do
          post :create, params: { team: { name: name, agency_id: agency.id } }
        end

        it 'creates the team' do
          team = Team.find_by(name: 'unique name')

          expect(team).to_not be_nil
          expect(team.users).to eq([user])
        end

        it 'redirects' do
          team = Team.find_by(name: 'unique name')
          expect(response).to redirect_to(team_users_path(team))
        end
      end
    end

    context 'when a login.gov admin' do
      let(:user) { create(:user, :logingov_admin) }

      context 'when it creates successfully' do
        it 'has a redirect response' do
          post :create, params: { team: { name: 'unique name', agency_id: agency.id } }

          team = Team.find_by(name: 'unique name')

          expect(team).to_not be_nil
          expect(team.users).to eq([])
          expect(response).to redirect_to(team_users_path(team))
        end
      end

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

      it 'has a redirect response' do
        delete :destroy, params: { id: org.id }
        expect(response).to have_http_status(:found)
      end
    end
    context 'when the user is not an admin'
    it 'has an error response' do
      delete :destroy, params: { id: org.id }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe '#edit' do
    context 'when login.gov admin' do
      let(:user) { create(:user, :logingov_admin) }

      it 'shows the edit template' do
        get :edit, params: { id: org.id }
        expect(response).to render_template(:edit)
      end
    end

    context 'when not an admin but a team member' do
      before do
        org.users << user
      end

      it 'shows the edit template' do
        get :edit, params: { id: org.id }
        expect(response).to render_template(:edit)
      end
    end
  end

  describe '#update' do
    context 'when login.gov admin' do
      let(:user) { create(:user, :logingov_admin) }

      context 'when the update is successful' do
        it 'has a redirect response' do
          patch :update, params: { id: org.id, team: { name: org.name }, new_user: { email: '' } }
          expect(response).to have_http_status(:found)
        end

        context 'when no update is made' do
          let(:user1)  { create(:team_member, teams: [org]) }
          let(:user2)  { create(:team_member, teams: [org]) }

          before do
            org.update(users: [user, user1, user2])
          end

          it 'has the same number of users after' do
            expect(org.users.count).to eq 3
            patch :update, params: {
              id: org.id,
              team: { name: org.name, agency_id: org.agency_id, description: org.description } }
            expect(org.users.count).to eq 3
          end
        end
      end

      context 'when the update is unsuccessful' do
        before do
          allow_any_instance_of(Team).to receive(:update).and_return(false)
        end

        it 'renders the edit action' do
          patch :update, params: {
            id: org.id, team: { name: org.name }, new_user: { email: '' }
          }
          expect(response).to render_template(:edit)
        end
      end
    end

    context 'when user is not login.gov admin but a member of the team' do
      before do
        org.users << user
      end

      context 'when no update is made' do
        let(:user1)  { create(:team_member, teams: [org]) }
        let(:user2)  { create(:team_member, teams: [org]) }

        before do
          org.update(users: [user, user1, user2])
        end

        it 'has the same number of users after' do
          expect(org.users.count).to eq 3
          patch :update, params: {
            id: org.id,
            team: {
              name: org.name,
              agency_id: org.agency_id,
              description: org.description,
            },
          user_ids: "#{user.id} #{user1.id} #{user2.id}" }
          expect(org.users.count).to eq 3
        end
      end
    end

    context 'when user is neither a login.gov admin nor a team member' do
      it 'has an unauthorized response' do
        patch :update, params: {
          id: org.id,
          team: {
            name: org.name,
            agency_id: org.agency_id,
            description: org.description,
          } }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
