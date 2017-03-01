require 'rails_helper'

feature 'Organizations CRUD' do
  scenario 'Create' do
    admin = create(:admin)
    agency = create(:agency)
    login_as(admin)

    visit new_organization_path

    fill_in 'Agency', with: 'agency name'
    fill_in 'Department', with: 'department name'
    fill_in 'Team', with: 'team name'
    
    click_on 'Create'

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

    expect(page).to have_content(org.agency)
    expect(page).to have_content(org.department)
    expect(page).to have_content(org.team)
  end

  scenario 'Delete' do
    admin = create(:admin)
    org = create(:organization)
    login_as(admin)

    visit organization_path(org)
    click_on 'Delete'

    expect(page).to have_content('Success')
  end
end

feature 'user must be an admin to access' do
  scenario 'only admin users are able to view organizations' do
    user = create(:user)
    create(:organization)
    login_as(user)

    visit organizations_path

    expect(page).to have_content('You are not authorized to perform this action.')
  end

  scenario 'only admin users are able to edit organizations' do
    user = create(:user)
    org = create(:organization)
    login_as(user)

    visit edit_organization_path(org)

    expect(page).to have_content('You are not authorized to perform this action.')
  end

  scenario 'only admin users are able to view an organization' do
    user = create(:user)
    org = create(:organization)
    login_as(user)

    visit organization_path(org)

    expect(page).to have_content('You are not authorized to perform this action.')
  end
end

feature 'admin can add service providers to an organization' do
  scenario 'admin adds a service_provider to an organization' do
    admin = create(:admin)
    sp = create(:service_provider, user: admin)
    org = create(:organization)
    login_as(admin)
    visit organization_path(org)
    select sp.friendly_name, from: 'service_provider[id]'
    within('.organization_service_proivders') do
      click_on 'Add to organization'
      expect(page).to have_content(sp.friendly_name)
    end
  end

  scenario 'admin removes a service_provider from an organization' do
    admin = create(:admin)
    org = create(:organization)
    sp = create(:service_provider, user: admin, organization_id: org.id)
    login_as(admin)
    visit organization_path(org)
    within('.org-sp-table') do
      click_on 'Remove'
    end
    within('.org-sp-table') do
      expect(page).to_not have_content(sp.friendly_name)
    end
  end
end

feature 'users can be added to an organization' do
  scenario 'admin adds a user to an organization' do
    expect(true).to eq(false)
  end

  scenario 'admin removes a user from an organization' do
    expect(true).to eq(false)
  end

  scenario 'a user in an organization has access to orgs service providers' do
    expect(true).to eq(false)
  end

  scenario 'user in an organization can edit an orgs service provider' do
    expect(true).to eq(false)
  end

end
