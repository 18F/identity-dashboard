require 'rails_helper'

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

  scenario 'index page shows user table' do
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
      expect(user_row).to have_button('Delete')
    end
  end

  scenario 'login.gov admin can delete unconfirmed users' do
    users = create_list(:user, 3)
    users[1].update(created_at: 20.days.ago)

    visit users_path

    click_on t('forms.buttons.delete_unconfirmed_users')
    expect(page).to have_content('Deleted 1 unconfirmed user')
  end

  scenario 'logingov_admin creates a user' do
    visit users_path
    click_on 'Create a new user'
    expect(page).to have_content('New user')
    expect(page).to_not have_content('Email can\'t be blank')
    click_on 'Create'
    expect(page).to have_content('New user')
    expect(page).to have_content('Email can\'t be blank')
    new_email = "test#{rand(1..10_000)}@test.domain"
    fill_in 'Email', with: new_email
    click_on 'Create'
    expect(page).to have_current_path(users_path)
    expect(User.last.email).to eq(new_email)
    expect(page).to have_content("#{new_email} User has not yet signed in")
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

    scenario 'index page shows user table' do
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
end
