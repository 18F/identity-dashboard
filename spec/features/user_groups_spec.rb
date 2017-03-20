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

  context 'User already in a user group' do
    scenario 'User does not show up as option for new group' do
      admin = create(:admin)
      user = create(:user)
      _user_group = create(:user_group, users: [user])

      login_as(admin)
      visit new_user_group_path

      expect(page).not_to have_content(user.email)
    end

    scenario 'User does show up in user group that they are assigned to' do
      admin = create(:admin)
      user = create(:user)
      user_group = create(:user_group, users: [user])

      login_as(admin)
      visit edit_user_group_path(user_group)

      expect(page).to have_content(user.email)
    end
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

  scenario 'Index' do
    admin = create(:admin)
    org1 = create(:user_group)
    org2 = create(:user_group)
    user_group = create(:user_group)
    sp = create(:service_provider, user_group: user_group)

    login_as(admin)
    visit user_groups_path

    expect(page).to have_content(org1.name)
    expect(page).to have_content(org2.name)
    expect(page).to have_content(org1.description)
    expect(page).to have_content(org2.description)
    expect(page).to have_content(sp.friendly_name)
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
