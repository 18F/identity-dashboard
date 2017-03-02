require 'rails_helper'

feature 'ServiceProviders CRUD' do
  scenario 'Create' do
    user = create(:user)
    agency = create(:agency)
    login_as(user)

    visit new_service_provider_path

    expect(page).to_not have_content('Approved')

    fill_in 'Friendly name', with: 'test service_provider'
    fill_in 'Issuer', with: 'test service_provider'
    select agency.name, from: 'service_provider[agency_id]'
    check 'email'
    check 'first_name'
    click_on 'Create'

    expect(page).to have_content('Success')
    within('table.horizontal-headers') do
      expect(page).to have_content('test service_provider')
      expect(page).to have_content('email')
      expect(page).to have_content('first_name')
    end
  end

  scenario 'Update' do
    user = create(:user)
    app = create(:service_provider, user: user)
    login_as(user)

    visit edit_service_provider_path(app)

    expect(page).to_not have_content('Approved')

    fill_in 'Friendly name', with: 'change service_provider name'
    fill_in 'Description', with: 'app description foobar'
    check 'last_name'
    click_on 'Update'

    expect(page).to have_content('Success')
    within('table.horizontal-headers') do
      expect(page).to have_content('app description foobar')
      expect(page).to have_content('change service_provider name')
      expect(page).to have_content('last_name')
    end
  end

  scenario 'Read' do
    user = create(:user)
    app = create(:service_provider, user: user)
    login_as(user)

    visit service_provider_path(app)

    expect(page).to have_content(app.friendly_name)
    expect(page).to_not have_content('All service providers')
  end

  scenario 'Delete' do
    user = create(:user)
    app = create(:service_provider, user: user)
    login_as(user)

    visit service_provider_path(app)
    click_on 'Delete'

    expect(page).to have_content('Success')
  end
end

feature 'Admin User Approval' do
  scenario 'only admin user has option to approve service_provider' do
    user = create(:user)
    login_as(user)

    visit new_service_provider_path

    expect(page).to_not have_content('Approved')
  end

  scenario 'admin user has option to approve service_provider' do
    app = create(:service_provider)
    admin_user = create(:user, admin: true)
    login_as(admin_user)

    visit edit_service_provider_path(app)

    expect(page).to have_content('Approved')
  end
end
