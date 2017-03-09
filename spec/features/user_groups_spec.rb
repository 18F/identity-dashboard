require 'rails_helper'

feature 'User groups CRUD' do
  scenario 'Create' do
    admin = create(:admin)
    user = create(:user)

    login_as(admin)
    visit new_user_group_path

    fill_in 'Description', with: 'department name'
    fill_in 'Name', with: 'team name'
    select user.email, from: 'Users'

    click_on 'Create'
    expect(current_path).to eq(user_groups_path)
    expect(page).to have_content('Success')
    expect(page).to have_content('team name')
    expect(page).to have_content('department name')
    expect(page).to have_content(user.email)
  end

  scenario 'Update' do
    admin = create(:admin)
    org = create(:user_group)
    login_as(admin)

    visit user_groups_path
    find("a[aria-label='#{t('links.aria.edit', name: org.name)}']").click

    expect(current_path).to eq(edit_user_group_path(org))

    fill_in 'Name', with: 'updated team'
    fill_in 'Description', with: 'updated department'
    click_on 'Update'

    expect(current_path).to eq(user_groups_path)
    expect(page).to have_content('Success')
    expect(page).to have_content('updated department')
    expect(page).to have_content('updated team')
  end

  scenario 'View Index' do
    admin = create(:admin)
    org1 = create(:user_group)
    org2 = create(:user_group)
    login_as(admin)

    visit user_groups_path

    expect(page).to have_content(org1.name)
    expect(page).to have_content(org2.name)
    expect(page).to have_content(org1.description)
    expect(page).to have_content(org2.description)
  end

  scenario 'Delete' do
    admin = create(:admin)
    org = create(:user_group)
    login_as(admin)

    visit user_groups_path
    find("a[aria-label='#{t('links.aria.delete', name: org.name)}']").click

    expect(current_path).to eq(user_groups_path)
    expect(page).to have_content('Success')
    expect(page).to_not have_content(org.name)
  end
end

feature 'Nav links include link to User Groups' do
  context 'user is admin' do
    scenario 'admin should see manage user groups link' do
      admin = create(:admin)
      login_as(admin)
      visit service_providers_path

      expect(page).to have_content(t('links.user_groups'))
    end
  end

  context 'user is not an admin' do
    scenario 'user should not see manage user group link' do
      user = create(:user)
      login_as(user)
      visit service_providers_path

      expect(page).to_not have_content(t('links.user_groups'))
    end
  end
end

feature 'Index page includes related service providers' do
  scenario 'User group has a service provider' do
    admin = create(:admin)
    ug = create(:user_group)
    sp = create(:service_provider, user_group: ug)
    login_as(admin)

    visit user_groups_path
    expect(page).to have_content(sp.friendly_name)
  end
end
