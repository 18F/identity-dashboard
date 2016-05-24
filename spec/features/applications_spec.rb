require 'rails_helper'

feature 'Applications CRUD' do
  scenario 'Create' do
    user = create(:user)
    login_as(user)

    visit new_users_application_path

    expect(page).to_not have_content('Approved')

    fill_in 'Name', with: 'test application'
    click_on 'Create'

    expect(page).to have_content('Success')
    expect(page).to have_content('test application')
  end

  scenario 'Update' do
    user = create(:user)
    app = create(:application, user: user)
    login_as(user)

    visit edit_users_application_path(app)

    expect(page).to_not have_content('Approved')

    fill_in 'Name', with: 'change application name'
    fill_in 'Description', with: 'app description foobar'
    click_on 'Update'

    expect(page).to have_content('Success')
    expect(page).to have_content('app description foobar')
    expect(page).to have_content('change application name')
  end

  scenario 'Read' do
    user = create(:user)
    app = create(:application, user: user)
    login_as(user)

    visit users_application_path(app)

    expect(page).to have_content(app.name)
  end

  scenario 'Delete' do
    user = create(:user)
    app = create(:application, user: user)
    login_as(user)

    visit users_application_path(app)
    click_on 'Delete'

    expect(page).to have_content('Success')
  end
end

feature 'Admin User Approval' do
  scenario 'only admin user has option to approve application' do
    user = create(:user)
    login_as(user)

    visit new_users_application_path

    expect(page).to_not have_content('Approved')
  end

  scenario 'admin user has option to approve application' do
    app = create(:application)
    admin_user = create(:user, admin: true)
    login_as(admin_user)

    visit edit_users_application_path(app)

    expect(page).to have_content('Approved')
  end
end

feature 'Email notification' do
  scenario 'app creation generates email to owner and admin' do
    user = create(:user)
    login_as(user)

    deliveries.clear # do not count User welcome

    visit new_users_application_path
    fill_in 'Name', with: 'test application'
    click_on 'Create'

    expect(deliveries.count).to eq(2)
    expect(page).to have_content('Success')
  end

  scenario 'approval generates email to owner and admin' do
    app = create(:application)
    admin_user = create(:user, admin: true)
    login_as(admin_user)

    deliveries.clear # do not count User welcome

    visit edit_users_application_path(app)
    choose('application_approved_true', option: 'true')
    click_on 'Update'

    expect(page).to have_content('Success')
    expect(deliveries.count).to eq(2)
  end
end
