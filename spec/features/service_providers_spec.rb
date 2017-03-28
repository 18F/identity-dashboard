require 'rails_helper'

feature 'Service Providers CRUD' do
  context 'Regular user' do
    scenario 'can create service provider' do
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

    scenario 'user group defaults to users user group' do
      ug = create(:user_group)
      user = create(:user, user_group: ug)
      login_as(user)

      visit new_service_provider_path
      expect(page).to have_select('service_provider_user_group_id', selected: ug.name)

      click_on 'Create'
      expect(page).to have_content(ug.name)
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

  context 'Update' do
    scenario 'user updates service provider' do
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

    context 'service provider does not have a user group' do
      scenario 'user group defaults to nil' do
        ug = create(:user_group)
        user = create(:user, user_group: ug)

        app = create(:service_provider, user: user)
        login_as(user)

        visit edit_service_provider_path(app)
        click_on 'Update'
        expect(page).to_not have_content(ug.name)
      end
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
