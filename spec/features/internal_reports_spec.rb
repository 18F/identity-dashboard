require 'rails_helper'

feature 'internal reports' do
  it 'responds with an error when not logged in' do
    visit internal_reports_memberships_path(format: 'csv')
    expect(body).to eq('You need to sign in or sign up before continuing.')
  end

  it 'responds with an error when not a logingov admin' do
    login_as create(:user)
    visit internal_reports_memberships_path(format: 'csv')
    expect(page).to have_http_status(:not_found)
  end

  describe 'with some users having multiple roles on different teams' do
    let(:logingov_admin) { create(:user, :logingov_admin) }
    let(:simple_user) { create(:user_team, :partner_developer).user }
    let(:two_teams_admin) { create(:user_team, :partner_admin).user }
    let(:complex_user) { create(:user_team, :partner_admin).user }
    let(:additional_team) { create(:team) }

    before do
      create(:user_team,
             user: two_teams_admin,
             team: simple_user.teams.first,
             role_name: 'partner_admin')
      create(:user_team,
             user: complex_user,
             team: additional_team,
             role_name: 'partner_readonly')
      create(:user_team,
             user: complex_user,
             team: simple_user.teams.first,
             role_name: 'partner_developer')
    end

    it 'can generate a CSV showing everything sorted' do
      login_as logingov_admin
      visit internal_reports_memberships_path(format: 'csv')
      expect(response_headers['content-type']).to start_with('text/csv')
      csv_response = CSV.parse(body)
      expect(csv_response.length).to eq(7)
      expect(csv_response[0]).to eq(['User email', 'Role', 'Team'])

      # Because we use `sequence(:email)` in the users factory,
      # the users should always sort into the order we created them
      admin_two_teams_names = two_teams_admin.teams.map(&:name).sort
      expect(csv_response[1]).to eq([
                                      two_teams_admin.email,
                                      'Partner Admin',
                                      admin_two_teams_names.first,
                                    ])
      expect(csv_response[2]).to eq([
                                      two_teams_admin.email,
                                      'Partner Admin',
                                      admin_two_teams_names.second,
                                    ])
      expect(csv_response[3]).to eq([
                                      simple_user.email,
                                      'Partner Developer',
                                      simple_user.teams.first.name,
                                    ])
      # With the same user, permissions should be in role order regardless of creation order
      remaining_team = complex_user.teams - simple_user.teams - [additional_team]
      expect(csv_response[4]).to eq([
                                      complex_user.email,
                                      'Partner Admin',
                                      remaining_team.first.name,
                                    ])
      expect(csv_response[5]).to eq([
                                      complex_user.email,
                                      'Partner Developer',
                                      simple_user.teams.first.name,
                                    ])
      expect(csv_response[6]).to eq([
                                      complex_user.email,
                                      'Partner Readonly',
                                      additional_team.name,
                                    ])
    end
  end
end
