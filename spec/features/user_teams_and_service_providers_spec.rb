require 'rails_helper'

feature 'Users can access service providers that belong to their team' do
  context 'user is not the creator of the service provider' do
    context 'Index' do
      scenario 'users can see the service provider on the team' do
        team = create(:team)
        user1 = create(:user, teams: [team])
        not_a_member_team = create(:team)
        user2 = create(:user)
        members_app = create(:service_provider, team: team, user: user2)
        no_longer_a_member_app = create(:service_provider, user: user1, team: not_a_member_team)
        other_app = create(:service_provider)

        login_as(user1)
        visit service_providers_path

        expect(page).to have_content(members_app.friendly_name)
        expect(page).to_not have_content(no_longer_a_member_app.friendly_name)
        expect(page).to_not have_content(other_app.friendly_name)
      end
    end

    context 'Edit' do
      scenario 'user can edit a service provider that belongs to a shared team' do
        team = create(:team)
        user1 = create(:user, teams: [team])
        user2 = create(:user)
        app = create(:service_provider, ial: 2, team: team, user: user2)
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
