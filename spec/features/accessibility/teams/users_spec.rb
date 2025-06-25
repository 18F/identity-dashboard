require 'rails_helper'
require 'axe-rspec'

feature 'team users page', :js do
  let(:team) { create(:team) }
  let(:team_memberships) do
    [
      create(:team_membership, :partner_admin, team:),
      create(:team_membership, :partner_readonly, team:),
      create(:team_membership, :partner_developer, team:),
    ]
  end

  before do
    login_as(create(:logingov_admin))
  end

  scenario 'on the index page' do
    team_memberships
    visit team_users_path(team)
    expect_page_to_have_no_accessibility_violations(page)
  end

  scenario 'on the new page' do
    team_memberships
    visit new_team_user_path(team)
    expect_page_to_have_no_accessibility_violations(page)
  end

  scenario 'on the edit page' do
    visit edit_team_user_path(team, team_memberships.sample.user)
    expect_page_to_have_no_accessibility_violations(page)
  end

  scenario 'on remove confirm page' do
    visit team_remove_confirm_path(team, team_memberships.sample.user)
    expect_page_to_have_no_accessibility_violations(page)
  end
end
