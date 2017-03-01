require 'rails_helper'

feature 'Organizations CRUD' do
  scenario 'Create' do
    admin = create(:admin)
    login_as(admin)

    visit new_organization_path

    fill_in 'Agency', with: 'agency name'
    fill_in 'Department', with: 'department name'
    fill_in 'Team', with: 'team name'

    click_on 'Create'
    expect(current_path).to eq(organization_path(Organization.last))
    expect(page).to have_content('Success')
    expect(page).to have_content('agency name')
    expect(page).to have_content('department name')
    expect(page).to have_content('team name')
  end

  scenario 'Update' do
    admin = create(:admin)
    org = create(:organization)
    login_as(admin)

    visit edit_organization_path(org)

    fill_in 'Agency', with: 'updated agency'
    fill_in 'Department', with: 'updated department'
    fill_in 'Team', with: 'updated team'
    click_on 'Update'

    expect(current_path).to eq(organization_path(org))
    expect(page).to have_content('Success')
    expect(page).to have_content('updated agency')
    expect(page).to have_content('updated department')
    expect(page).to have_content('updated team')
  end

  scenario 'Read' do
    admin = create(:admin)
    org = create(:organization)
    login_as(admin)

    visit organization_path(org)

    expect(page).to have_content(org.agency_name)
    expect(page).to have_content(org.department_name)
    expect(page).to have_content(org.team_name)
  end

  scenario 'View Index' do
    admin = create(:admin)
    org1 = create(:organization)
    org2 = create(:organization)
    login_as(admin)

    visit organizations_path

    expect(page).to have_content(org1.agency_name)
    expect(page).to have_content(org2.agency_name)
    expect(page).to have_content(org1.department_name)
    expect(page).to have_content(org2.department_name)
    expect(page).to have_content(org1.team_name)
    expect(page).to have_content(org2.team_name)
  end

  scenario 'Delete' do
    admin = create(:admin)
    org = create(:organization)
    login_as(admin)

    visit organization_path(org)
    click_on 'Delete'

    expect(current_path).to eq(organizations_path)
    expect(page).to have_content('Success')
    expect(page).to_not have_content(org.agency_name)
  end
end
