require 'rails_helper'

feature 'Applications CRUD' do
  scenario 'Create' do
    user = create(:user)
    login_as(user)

    visit new_users_application_path

    fill_in 'Name', with: 'test application'
    click_on 'Create'

    expect(page).to have_content('Success')
    expect(page).to have_content('test application')
  end

  scenario 'Update' do
    app = create(:application)
    user = create(:user)
    login_as(user)

    visit edit_users_application_path(app)

    fill_in 'Name', with: 'change application name'
    fill_in 'Description', with: 'app description foobar'
    click_on 'Update'

    expect(page).to have_content('Success')
    expect(page).to have_content('app description foobar')
    expect(page).to have_content('change application name')
  end

  scenario 'Read' do
    app = create(:application)
    user = create(:user)
    login_as(user)

    visit users_application_path(app)

    expect(page).to have_content(app.name)
  end

  scenario 'Delete' do
    app = create(:application)
    user = create(:user)
    login_as(user)

    visit users_application_path(app)
    click_on 'Delete'

    expect(page).to have_content('Success')
  end 
end
    
