require 'rails_helper'

feature 'User groups CRUD' do
  scenario 'Create' do
    admin = create(:admin)
    user = create(:user)
    create(:agency, name: 'GSA')

    login_as(admin)
    visit new_group_path

    fill_in 'Description', with: 'department name'
    fill_in 'Name', with: 'team name'
    select('GSA', from: 'Agency')
    find("#group_user_ids_#{user.id}").click

    click_on 'Create'
    expect(current_path).to eq(group_path(Group.last))
    expect(page).to have_content('Success')
    expect(page).to have_content('team name')
    expect(page).to have_content('GSA')
    expect(page).to have_content('department name')
    expect(page).to have_content(user.email)
  end

  context 'User already in a group' do
    scenario 'User does show up in user group that they are assigned to' do
      admin = create(:admin)
      user = create(:user)
      group = create(:group, users: [user])

      login_as(admin)
      visit edit_group_path(group)

      expect(page).to have_content(user.email)
    end

    scenario 'User can be added to another group' do
      admin = create(:admin)
      user = create(:user)
      group1 = create(:group, users: [user])
      group2 = create(:group)

      login_as(admin)
      visit edit_group_path(group2)
      find("#group_user_ids_#{user.id}").click

      click_on 'Update'
      expect(user.groups).to include(group1, group2)
    end
  end

  scenario 'Update' do
    admin = create(:admin)
    org = create(:group)
    create(:agency, name: 'USDS')
    login_as(admin)

    visit groups_path
    find("a[href='#{edit_group_path(org)}']").click
    expect(current_path).to eq(edit_group_path(org))

    fill_in 'Name', with: 'updated team'
    fill_in 'Description', with: 'updated department'
    fill_in 'Add new group user (email)', with: 'new_user@gsa.gov'
    select('USDS', from: 'Agency')
    click_on 'Update'

    expect(current_path).to eq(group_path(org.id))
    expect(page).to have_content('Success')
    expect(page).to have_content('USDS')
    expect(page).to have_content('updated department')
    expect(page).to have_content('updated team')
    expect(page).to have_content('new_user@gsa.gov')
  end

  scenario 'Index' do
    admin = create(:admin)
    org1 = create(:group)
    org2 = create(:group)
    group = create(:group)
    sp = create(:service_provider, group: group)

    login_as(admin)
    visit groups_path

    expect(page).to have_content(org1.name)
    expect(page).to have_content(org2.name)
    expect(page).to have_content(org1.agency.name)
    expect(page).to have_content(org2.agency.name)
    expect(page).to have_content(org1.description)
    expect(page).to have_content(org2.description)
    expect(page).to have_content(sp.friendly_name)
  end

  describe 'show' do
    scenario 'admin views a group' do
      admin = create(:admin)
      group = create(:group)
      user = create(:user, groups: [group])
      create(:service_provider, group: group)

      login_as(admin)
      visit groups_path
      find("a[href='#{group_path(group)}']", text: 'view').click

      expect(current_path).to eq(group_path(group))
      expect(page).to have_content(group.name)
      expect(page).to have_content(group.agency.name)
      expect(page).to have_content(user.email)
    end

    scenario 'regular user attempts to view a group' do
      user = create(:user)
      group = create(:group)
      create(:service_provider, group: group)

      login_as(user)

      visit group_path(group)

      expect(page).to_not have_content(group.name)
      expect(page).to have_content('Unauthorized')
    end
  end

  scenario 'Delete' do
    admin = create(:admin)
    group = create(:group)
    login_as(admin)

    visit groups_path
    find("a[href='#{group_path(group)}']", text: 'delete').click

    expect(current_path).to eq(groups_path)
    expect(page).to have_content('Success')
    expect(page).to_not have_content(group.name)
  end
end
