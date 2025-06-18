require 'rails_helper'
require 'axe-rspec'

feature 'team users page', :js do
  let(:team) { create(:team) }
  let(:memberships) do
    [
      create(:membership, :partner_admin, team:),
      create(:membership, :partner_readonly, team:),
      create(:membership, :partner_developer, team:),
    ]
  end

  before do
    login_as(create(:logingov_admin))
  end

  scenario 'on the index page' do
    memberships
    visit team_users_path(team)
    expect_page_to_have_no_accessibility_violations(page)
  end

  scenario 'on the new page' do
    memberships
    visit new_team_user_path(team)
    expect_page_to_have_no_accessibility_violations(page)
  end

  scenario 'on the edit page' do
    visit edit_team_user_path(team, memberships.sample.user)
    expect_page_to_have_no_accessibility_violations(page)
  end

  scenario 'on remove confirm page' do
    visit team_remove_confirm_path(team, memberships.sample.user)
    expect_page_to_have_no_accessibility_violations(page)
  end
end