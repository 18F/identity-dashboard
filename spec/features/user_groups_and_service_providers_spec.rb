require 'rails_helper'

feature 'Users can access service providers that belong to their user group' do
  context 'user is not the creator of the service provider' do
    context 'Index' do
      scenario 'users in the related user group can see the service provider' do
        group = create(:group)
        user1 = create(:user, groups: [group])
        user2 = create(:user)
        user_group_app = create(:service_provider, group: group, user: user2)
        user_created_app = create(:service_provider, user: user1)
        na_app = create(:service_provider)

        login_as(user1)
        visit service_providers_path

        expect(page).to have_content(user_group_app.friendly_name)
        expect(page).to have_content(user_created_app.friendly_name)
        expect(page).to_not have_content(na_app.friendly_name)
      end
    end

    context 'Edit' do
      scenario 'user can edit a service provider from their user group' do
        group = create(:group)
        user1 = create(:user, groups: [group])
        user2 = create(:user)
        app = create(:service_provider, group: group, user: user2)
        new_name = 'New Service Name'
        new_description = 'New Description'

        login_as(user1)
        visit edit_service_provider_path(app)
        fill_in 'Friendly name', with: new_name
        fill_in 'Description', with: new_description
        check 'last_name'
        click_on 'Update'

        expect(page).to have_content('Success')
        expect(page).to have_content(new_name)
        expect(page).to have_content(new_description)
        expect(page).to have_content('last_name')
      end
    end
  end
end
