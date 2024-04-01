require 'rails_helper'
require 'axe-rspec'

feature 'Team pages', :js do
  let(:admin) { create(:admin) }

  before do
    login_as(admin)
  end

  scenario 'index page is accessible' do
    visit teams_path
    expect_page_to_have_no_accessibility_violations(page)
  end

  scenario 'All teams page is accessible' do
    visit teams_all_path
    expect_page_to_have_no_accessibility_violations(page)
  end

  scenario 'New team page is accessible' do
    visit new_team_path
    expect_page_to_have_no_accessibility_violations(page)
  end

  scenario 'Edit team page is accessible' do
    user = create(:user)
    team = create(:team, users: [user])
    visit edit_team_path(team)
    expect_page_to_have_no_accessibility_violations(page)
  end

  scenario 'New team user page is accessible' do
    create(:agency, name: 'GSA')

    visit new_team_path

    fill_in 'Description', with: 'department name'
    fill_in 'Name', with: 'team name'
    select('GSA', from: 'Agency')

    click_on 'Create'
    expect_page_to_have_no_accessibility_violations(page)
  end
end
