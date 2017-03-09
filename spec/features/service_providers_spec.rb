require 'rails_helper'

feature 'ServiceProviders CRUD' do
  context 'Regular user' do
    scenario 'can create service provider' do
      user = create(:user)
      agency = create(:agency)
      login_as(user)

      visit new_service_provider_path

      expect(page).to_not have_content('Approved')
      expect(page).to_not have_select('service_provider_user_group_id')

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

    context 'admin user' do
      scenario 'can create service provider with user group and approval' do
        admin = create(:admin)
        agency = create(:agency)
        group = create(:user_group)
        login_as(admin)

        visit new_service_provider_path

        choose('service_provider_approved_true')
        select group, from: 'service_provider[user_group_id]'
        fill_in 'Friendly name', with: 'test service_provider'
        fill_in 'Issuer', with: 'test service_provider'
        select agency.name, from: 'service_provider[agency_id]'
        check 'email'
        check 'first_name'
        click_on 'Create'

        expect(page).to have_content('Success')
      end
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
    group = create(:user_group)
    app = create(:service_provider, user_group: group, user: user)
    login_as(user)

    visit service_provider_path(app)

    expect(page).to have_content(app.friendly_name)
    expect(page).to have_content(group)
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

feature 'Users can access sps in their user group' do
  context 'user is not the creator of the app' do
    scenario 'service providers from a user group show on index' do
      group = create(:user_group)
      user1 = create(:user, user_group: group)
      user2 = create(:user)
      user_group_app = create(:service_provider, user_group: group, user: user2)
      user_created_app = create(:service_provider, user: user1)
      na_app = create(:service_provider)
      login_as(user1)

      visit service_providers_path

      expect(page).to have_content(user_group_app.friendly_name)
      expect(page).to have_content(user_created_app.friendly_name)
      expect(page).to_not have_content(na_app.friendly_name)
    end

    scenario 'user can edit a service provider from their user group' do
      group = create(:user_group)
      user1 = create(:user, user_group: group)
      user2 = create(:user)
      app = create(:service_provider, user_group: group, user: user2)
      new_name = 'New Service Name'
      new_description = 'New Description'

      login_as(user1)

      visit edit_service_provider_path(app)
      fill_in 'Friendly name', with: new_name
      fill_in 'Description', with: new_description
      check 'last_name'
      click_on 'Update'

      expect(page).to have_content('Success')
      within('table.horizontal-headers') do
        expect(page).to have_content(new_name)
        expect(page).to have_content(new_description)
        expect(page).to have_content('last_name')
      end
    end
  end
end
