require 'rails_helper'

feature 'internal reports' do
  let(:logingov_admin) { create(:user, :logingov_admin) }

  it 'responds with an error when not logged in' do
    visit internal_reports_team_memberships_path(format: 'csv')
    expect(body).to eq('You need to sign in or sign up before continuing.')
  end

  it 'responds with an error when not a logingov admin' do
    login_as create(:user)
    visit internal_reports_team_memberships_path(format: 'csv')
    expect(page).to have_http_status(:not_found)
  end

  describe 'with some users having multiple roles on different teams' do
    let(:simple_user) { create(:team_membership, :partner_developer).user }
    let(:two_teams_admin) { create(:team_membership, :partner_admin).user }
    let(:complex_user) { create(:team_membership, :partner_admin).user }
    let(:additional_team) { create(:team) }

    before do
      create(:team_membership,
             user: two_teams_admin,
             team: simple_user.teams.first,
             role_name: 'partner_admin')
      create(:team_membership,
             user: complex_user,
             team: additional_team,
             role_name: 'partner_readonly')
      create(:team_membership,
             user: complex_user,
             team: simple_user.teams.first,
             role_name: 'partner_developer')
    end

    it 'can generate a CSV showing everything sorted' do
      login_as logingov_admin
      visit internal_reports_team_memberships_path(format: 'csv')
      expect(response_headers['content-type']).to start_with('text/csv')
      csv_response = CSV.parse(body)
      expected_table = expected_table_for(
        two_teams_admin,
        simple_user,
        complex_user,
        additional_team,
      )
      expect(csv_response.length).to eq(8)
      expect(csv_response).to eq(expected_table)
    end
  end

  def expected_table_for(first_user, second_user, third_user, shared_team)
    admin_two_teams_names = two_teams_admin.teams.map(&:name).sort
    remaining_team = complex_user.teams - simple_user.teams - [additional_team]
    # Because we use `sequence(:email)` in the users factory,
    # the users should always sort into the order we created them
    [
      TeamMembershipCsv::HEADER_ROW,
      [
        two_teams_admin.email,
        'Partner Admin',
        admin_two_teams_names.first,
      ],
      [
        two_teams_admin.email,
        'Partner Admin',
        admin_two_teams_names.second,
      ],
      [
        simple_user.email,
        'Partner Developer',
        simple_user.teams.first.name,
      ],
      # With the same user, permissions should be in role order regardless of creation order
      [
        complex_user.email,
        'Partner Admin',
        remaining_team.first.name,
      ],
      [
        complex_user.email,
        'Partner Developer',
        simple_user.teams.first.name,
      ],
      [
        complex_user.email,
        'Partner Readonly',
        additional_team.name,
      ],
      [
        logingov_admin.email,
        'Login.gov Admin',
        Team.internal_team.name,
      ],
    ]
  end
end
