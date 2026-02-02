require 'rails_helper'

feature 'internal reports' do
  let(:logingov_admin) { create(:user, :logingov_admin) }
  let(:logingov_readonly) { create(:user, :logingov_readonly) }

  it 'responds with an error when not logged in' do
    visit internal_reports_user_permissions_path(format: 'csv')
    expect(body).to eq('You need to sign in or sign up before continuing.')
  end

  it 'responds with an error when not logingov staff' do
    login_as create(:user)
    visit internal_reports_user_permissions_path(format: 'csv')
    expect(page).to have_http_status(:not_found)
  end

  describe 'with some users having multiple roles on different teams' do
    let(:simple_user) { create(:team_membership, :partner_developer).user }
    let(:two_teams_admin) { create(:team_membership, :partner_admin).user }
    let(:complex_user) { create(:team_membership, :partner_admin).user }
    let(:additional_team) { create(:team) }
    # Report showing all issuers requires ServiceProviders
    let!(:sp0) { create(:service_provider, team: simple_user.teams.first) }
    let!(:sp1) { create(:service_provider, team: simple_user.teams.first) }
    let!(:sp2) { create(:service_provider, team: additional_team) }
    let!(:sp3) { create(:service_provider, team: additional_team) }

    before do
      # Report shows TeamMembership for each issuer
      create(:team_membership,
             user: two_teams_admin,
             team: simple_user.teams.first,
             role_name: 'partner_admin')
      create(:team_membership,
             user: two_teams_admin,
             team: additional_team,
             role_name: 'partner_readonly')
      create(:team_membership,
             user: complex_user,
             team: simple_user.teams.first,
             role_name: 'partner_developer')
    end

    describe 'can generate a CSV showing everything sorted' do
      before do
        # add staff to internal team
        logingov_admin
        logingov_readonly
      end

      it 'when user is Login.gov Admin' do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)

        login_as logingov_admin
        visit internal_reports_user_permissions_path(format: 'csv')
        expect(response_headers['content-type']).to start_with('text/csv')
        csv_response = CSV.parse(body)

        expect(csv_response.length).to eq(11)

        expect(csv_response).to eq(expected_table)
      end

      it 'when user is Login.gov Readonly' do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)

        login_as logingov_readonly
        visit internal_reports_user_permissions_path(format: 'csv')
        expect(response_headers['content-type']).to start_with('text/csv')
        csv_response = CSV.parse(body)

        expect(csv_response.length).to eq(11)

        expect(csv_response).to eq(expected_table)
      end
    end
  end

  describe 'includes users without team memberships' do
    let!(:user_without_team) { create(:user, email: 'orphan@example.gov') }

    it 'shows the user with empty team and role fields' do
      allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)

      login_as logingov_admin
      visit internal_reports_user_permissions_path(format: 'csv')
      csv_response = CSV.parse(body)

      orphan_row = csv_response.find { |row| row[3] == user_without_team.email }
      expect(orphan_row).to eq(['', '', '', user_without_team.email, ''])
    end
  end

  def expected_table
    [
      ['Issuer', 'Team', 'Team UUID', 'User email', 'Role'],
      [
        '',
        Team.internal_team.name,
        Team.internal_team.uuid,
        logingov_admin.email,
        'Login.gov Admin',
      ],
      [
        '',
        Team.internal_team.name,
        Team.internal_team.uuid,
        logingov_readonly.email,
        'Login.gov Readonly',
      ],
      [
        sp0.issuer,
        simple_user.teams.first.name,
        simple_user.teams.first.uuid,
        simple_user.email,
        'Production Team Dev',
      ],
      [
        sp0.issuer,
        simple_user.teams.first.name,
        simple_user.teams.first.uuid,
        two_teams_admin.email,
        'Production Team Admin',
      ],
      [
        sp0.issuer,
        simple_user.teams.first.name,
        simple_user.teams.first.uuid,
        complex_user.email,
        'Production Team Dev',
      ],
      [
        sp1.issuer,
        simple_user.teams.first.name,
        simple_user.teams.first.uuid,
        simple_user.email,
        'Production Team Dev',
      ],
      [
        sp1.issuer,
        simple_user.teams.first.name,
        simple_user.teams.first.uuid,
        two_teams_admin.email,
        'Production Team Admin',
      ],
      [
        sp1.issuer,
        simple_user.teams.first.name,
        simple_user.teams.first.uuid,
        complex_user.email,
        'Production Team Dev',
      ],
      [
        sp2.issuer,
        additional_team.name,
        additional_team.uuid,
        two_teams_admin.email,
        'Team Readonly',
      ],
      [
        sp3.issuer,
        additional_team.name,
        additional_team.uuid,
        two_teams_admin.email,
        'Team Readonly',
      ],
    ]
  end
end
