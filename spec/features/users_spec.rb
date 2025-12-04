require 'rails_helper'

def flag_in
  allow(IdentityConfig.store).to receive_messages(access_controls_enabled: true)
end

def flag_out
  allow(IdentityConfig.store).to receive_messages(access_controls_enabled: false)
end

feature 'login.gov admin manages users' do
  let(:logingov_admin) { create(:logingov_admin) }

  before { login_as(logingov_admin) }

  scenario 'manage user page accessible from nav bar link' do
    visit service_providers_path
    click_on 'Users'

    expect(page).to have_current_path(users_path)
  end

  scenario 'user index page shows all users' do
    users = create_list(:user, 3)

    visit users_path

    users.each do |user|
      expect(page).to have_content(user.email)
    end
  end

  scenario 'rbac flag index page shows user table' do
    flag_in
    users = create_list(:user, 3)
    everyone = [logingov_admin, users].flatten
    headings = ['Email', 'Signed in', 'Role', 'Actions']

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
    users = create_list(:user, 3)
    users[1].update(created_at: 20.days.ago)

    visit users_path

    click_on t('forms.buttons.delete_unconfirmed_users')
    expect(page).to have_content('Deleted 1 unconfirmed user')
  end

  [:flag_in, :flag_out].each do |flag|
    scenario "logingov_admin creates a user with RBAC #{flag}" do
      send flag
      visit users_path
      click_on 'Create a new user'
      expect(page).to have_content('New user')
      expect(page).to_not have_content('Email can\'t be blank')
      click_on 'Create'
      expect(page).to have_content('New user')
      expect(page).to have_content('Email can\'t be blank')
      new_email = "test#{rand(1..10000)}@test.domain"
      fill_in 'Email', with: new_email
      click_on 'Create'
      expect(page).to have_current_path(users_path)
      expect(User.last.email).to eq(new_email)
      expect(page).to have_content("#{new_email} User has not yet signed in")
    end

    scenario "logingov_admin edits users with RBAC #{flag}" do
      user = create(:user, :with_teams)

      visit users_path
      expect(find('tr', text: user.email)).to_not have_content('Login.gov Admin')
      find("a[href='#{edit_user_path(user)}']").click

      expect(page).to have_current_path(edit_user_path(user))
      email_field = find_field('user_email', disabled: true)
      expect(email_field.value).to eq(user.email)

      choose 'Login.gov Admin'
      click_on 'Update'

      expect(page).to have_current_path(users_path)
      expect(find('tr', text: user.email)).to have_content('Login.gov Admin')
    end
  end

  feature 'login.gov readonly views users' do
    let(:logingov_readonly) { create(:logingov_readonly) }

    before { login_as(logingov_readonly) }

    scenario 'manage user page accessible from nav bar link' do
      visit service_providers_path
      click_on 'Users'

      expect(page).to have_current_path(users_path)
    end

    scenario 'create and delete buttons are hidden' do
      visit users_path

      expect(page).to_not have_content('New User')
      expect(page).to_not have_content('Delete unconfirmed users')
    end

    scenario 'user index page shows all users' do
      users = create_list(:user, 3)

      visit users_path

      users.each do |user|
        expect(page).to have_content(user.email)
      end
    end

    scenario 'rbac flag index page shows user table' do
      flag_in
      users = create_list(:user, 3)
      everyone = [logingov_readonly, users].flatten
      headings = ['Email', 'Signed in', 'Role']

      visit users_path

      headings.each do |heading|
        expect(page).to have_content(heading)
      end
      everyone.each do |user|
        user_row = find('tr', text: user.email)
        expect(user_row).to have_content(user.primary_role.friendly_name)
      end
    end
  end

  scenario 'rbac flag shows edit for user on teams' do
    flag_in
    roles = ['Login.gov Admin',
             'Login.gov Readonly',
             'Sandbox Partner Admin',
             'Sandbox Team Dev',
             'Team Readonly']

    visit edit_user_path(create(:user, :with_teams))

    expect(page).to have_content('Permissions')
    radio_labels = find_all('.usa-radio__label').map(&:text)
    roles.each do |role|
      expect(radio_labels).to include(role)
    end
  end

  scenario 'when no teams assigned permissions limited to site admin promotion/demotion' do
    flag_in
    user_to_edit = create(:user)
    visit edit_user_path(user_to_edit)

    expect(page).to have_content('Permissions')
    radio_labels = find_all('.usa-radio__label').map(&:text)
    expect(radio_labels).to eq(['Login.gov Admin',
                                'Login.gov Readonly',
                                'Sandbox Partner Admin'])
    expect(find_all('input[type=radio]').last).to be_checked
    find_all('input[type=radio]').first.click
    click_on 'Update'
    expect(user_to_edit.reload).to be_logingov_admin

    visit edit_user_path(user_to_edit)
    expect(find_all('input[type=radio]').first).to be_checked
    find_all('input[type=radio]').last.click
    click_on 'Update'
    expect(user_to_edit.reload).to_not be_logingov_admin
  end

  scenario 'can change Login.gov Admin to Login.gov Readonly role' do
    flag_in
    user_to_edit = create(:user, :logingov_admin)
    visit edit_user_path(user_to_edit)
    choose 'Login.gov Readonly'
    click_on 'Update'
    expect(page).to have_http_status(:ok)
    expect(user_to_edit.reload).to_not be_logingov_admin
    expect(user_to_edit).to be_logingov_readonly
  end

  scenario 'can change Login.gov Readonly to Login.gov Admin role' do
    flag_in
    user_to_edit = create(:user, :logingov_readonly)
    visit edit_user_path(user_to_edit)
    choose 'Login.gov Admin'
    click_on 'Update'
    expect(page).to have_http_status(:ok)
    expect(user_to_edit.reload).to_not be_logingov_readonly
    expect(user_to_edit).to be_logingov_admin
  end

  scenario 'can demote a legacy Login.gov admin and make them a Login.gov admin again' do
    legacy_admin_user = create(:user, admin: true)
    visit edit_user_path(legacy_admin_user)
    choose 'Sandbox Partner Admin'
    click_on 'Update'
    expect(page).to have_http_status(:ok)
    expect(legacy_admin_user.reload).to_not be_logingov_admin
    expect(legacy_admin_user.admin).to be_falsey
    visit edit_user_path(legacy_admin_user)
    choose 'Login.gov Admin'
    click_on 'Update'
    expect(page).to have_http_status(:ok)
    expect(legacy_admin_user.reload).to be_logingov_admin
    expect(legacy_admin_user.teams).to include(Team.internal_team)

    # Promoting to Admin should be idempotent
    visit edit_user_path(legacy_admin_user)
    choose 'Login.gov Admin'
    click_on 'Update'
    expect(page).to have_http_status(:ok)
    expect(legacy_admin_user.reload).to be_logingov_admin
    expect(legacy_admin_user.teams).to include(Team.internal_team)
  end
end
