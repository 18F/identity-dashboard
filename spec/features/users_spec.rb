require 'rails_helper'

def flag_in
  allow(IdentityConfig.store).to receive_messages(access_controls_enabled: true)
end

feature 'login.gov admin manages users' do
  scenario 'manage user page accessible from nav bar link' do
    logingov_admin = create(:logingov_admin)

    login_as(logingov_admin)
    visit service_providers_path
    click_on 'Users'

    expect(page).to have_current_path(users_path)
  end

  scenario 'user index page shows all users' do
    logingov_admin = create(:logingov_admin)
    users = create_list(:user, 3)

    login_as(logingov_admin)
    visit users_path

    users.each do |user|
      expect(page).to have_content(user.email)
    end
  end

  scenario 'rbac flag index page shows user table' do
    flag_in
    logingov_admin = create(:logingov_admin)
    users = create_list(:user, 3)
    everyone = [logingov_admin, users].flatten
    headings = ['Email', 'Signed in', 'Role', 'Actions']

    login_as(logingov_admin)
    visit users_path

    headings.each do |heading|
      expect(page).to have_content(heading)
    end
    everyone.each do |user|
      user_row = find('tr', text: user.email)
      expect(user_row).to have_content(user.primary_role.friendly_name)
    end
  end

  scenario 'login.gov admin can delete unconfirmed users' do
    logingov_admin = create(:logingov_admin)
    users = create_list(:user, 3)
    users[1].update(created_at: 20.days.ago)

    login_as(logingov_admin)
    visit users_path

    click_on t('forms.buttons.remove_unconfirmed_users')
    expect(page).to have_content('Deleted 1 unconfirmed user')
  end

  scenario 'logingov_admin edits users' do
    logingov_admin = create(:logingov_admin)
    user = create(:user)

    login_as(logingov_admin)
    visit users_path
    expect(find('tr', text: user.email)).to_not have_content('Login.gov Admin')
    find("a[href='#{edit_user_path(user)}']").click

    expect(page).to have_current_path(edit_user_path(user))
    expect(find_field('user_email').value).to eq(user.email)

    choose 'Login.gov Admin'
    click_on 'Update'

    expect(page).to have_current_path(users_path)
    expect(find('tr', text: user.email)).to have_content('Login.gov Admin')
  end

  scenario 'rbac flag shows edit user permissions' do
    flag_in
    logingov_admin = create(:logingov_admin)
    roles = ['Login.gov Admin',
             'Partner Admin',
             'Partner Developer',
             'Partner Readonly']

    login_as(logingov_admin)
    visit edit_user_path(logingov_admin.id)

    expect(page).to have_content('Permissions')
    radio_labels = find_all('.usa-radio__label').map(&:text)
    roles.each do |role|
      expect(radio_labels).to include(role)
    end
  end
end
