require 'rails_helper'

feature 'User groups CRUD' do
  scenario 'Create' do
    admin = create(:admin)
    login_as(admin)

    visit new_user_group_path

    fill_in 'Description', with: 'department name'
    fill_in 'Name', with: 'team name'

    click_on 'Create'
    expect(current_path).to eq(user_group_path(UserGroup.last))
    expect(page).to have_content('Success')
    expect(page).to have_content('team name')
    expect(page).to have_content('department name')
  end

  scenario 'Update' do
    admin = create(:admin)
    org = create(:user_group)
    login_as(admin)

    visit edit_user_group_path(org)

    fill_in 'Name', with: 'updated team'
    fill_in 'Description', with: 'updated department'
    click_on 'Update'

    expect(current_path).to eq(user_group_path(org))
    expect(page).to have_content('Success')
    expect(page).to have_content('updated department')
    expect(page).to have_content('updated team')
  end

  scenario 'Read' do
    admin = create(:admin)
    org = create(:user_group)
    login_as(admin)

    visit user_group_path(org)

    expect(page).to have_content(org.name)
    expect(page).to have_content(org.description)
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

    visit user_group_path(org)
    click_on 'Delete'

    expect(current_path).to eq(user_groups_path)
    expect(page).to have_content('Success')
    expect(page).to_not have_content(org.name)
  end
end
