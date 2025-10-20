require 'rails_helper'

feature 'internal reports' do
  let(:logingov_admin) { create(:user, :logingov_admin) }

  it 'responds with an error when not logged in' do
    visit internal_reports_user_permissions_path(format: 'csv')
    expect(body).to eq('You need to sign in or sign up before continuing.')
  end

  it 'responds with an error when not a logingov admin' do
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
    let(:sp0) { create(:service_provider, team: simple_user.teams.first) }
    let(:sp1) { create(:service_provider, team: simple_user.teams.first) }
    let(:sp2) { create(:service_provider, team: additional_team) }
    let(:sp3) { create(:service_provider, team: additional_team) }

    before do
      # ensure ServiceProviders are created for each test
      sp0.issuer
      sp1.issuer
      sp2.issuer
      sp3.issuer
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

    it 'can generate a CSV showing everything sorted' do
      login_as logingov_admin
      visit internal_reports_user_permissions_path(format: 'csv')
      expect(response_headers['content-type']).to start_with('text/csv')
      csv_response = CSV.parse(body)

      expect(csv_response.length).to eq(10)
      puts csv_response
      puts expected_table
      expected_table.each_with_index do |row, index|
        expect(csv_response[index]).to eq(row)
      end
      # expect(csv_response).to eq(expected_table)
    end
  end

  def expected_table
    [
      ['Issuer', 'Team', 'Team UUID', 'User email', 'Role'],
      [
        sp0.issuer,
        simple_user.teams.first.name,
        simple_user.teams.first.uuid,
        simple_user.email,
        'Partner Developer',
      ],
      [
        sp0.issuer,
        simple_user.teams.first.name,
        simple_user.teams.first.uuid,
        two_teams_admin.email,
        'Partner Admin',
      ],
      [
        sp0.issuer,
        simple_user.teams.first.name,
        simple_user.teams.first.uuid,
        complex_user.email,
        'Partner Developer',
      ],
      [
        sp1.issuer,
        simple_user.teams.first.name,
        simple_user.teams.first.uuid,
        simple_user.email,
        'Partner Developer',
      ],
      [
        sp1.issuer,
        simple_user.teams.first.name,
        simple_user.teams.first.uuid,
        two_teams_admin.email,
        'Partner Admin',
      ],
      [
        sp1.issuer,
        simple_user.teams.first.name,
        simple_user.teams.first.uuid,
        complex_user.email,
        'Partner Developer',
      ],
      [
        sp2.issuer,
        additional_team.name,
        additional_team.uuid,
        two_teams_admin.email,
        'Partner Readonly',
      ],
      [
        sp3.issuer,
        additional_team.name,
        additional_team.uuid,
        two_teams_admin.email,
        'Partner Readonly',
      ],
      [
        '',
        Team.internal_team.name,
        Team.internal_team.uuid,
        logingov_admin.email,
        'Login.gov Admin',
      ],
    ]
  end
end
