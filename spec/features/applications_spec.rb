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

  scenario 'non-owner attempts to view' do
    user = create(:user)
    app = create(:application)
    login_as(user)

    visit users_application_path(app)

    expect(page.status_code).to eq(401)
  end

  scenario 'admin attempts to view' do
    admin_user = create(:user, admin: true)
    app = create(:application)
    login_as(admin_user)

    visit users_application_path(app)

    expect(page.status_code).to eq(200)
  end
end

feature 'Admin User Approval' do
  scenario 'new application' do
    ActionMailer::Base.deliveries.clear

    # create as normal user
    user = create(:user)
    login_as(user)

    visit new_users_application_path

    expect(page).to_not have_content('Approved')

    fill_in 'Name', with: 'test application'
    click_on 'Create'

    expect(ActionMailer::Base.deliveries.count).to eq(2)
    expect(page).to have_content('Success')

    app = Application.all.last

    # update as admin user
    admin_user = create(:user, admin: true)
    login_as(admin_user)

    visit edit_users_application_path(app)

    expect(page).to have_content('Approved')

    choose('application_approved_true', option: 'true')
    click_on 'Update'

    expect(page).to have_content('Success')
    app.reload
    expect(app.approved?).to eq true
    expect(ActionMailer::Base.deliveries.count).to eq(4)
  end
end 
