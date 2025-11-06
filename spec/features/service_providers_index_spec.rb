require 'rails_helper'

feature 'Users can access service providers that belong to their team' do
  context 'Index' do
    let(:team0) { create(:team) }
    let(:user1) { create(:user, teams: [team0]) }
    let(:not_a_member_team) { create(:team) }
    let(:user2) { create(:user) }

    scenario 'sandbox users can see all configs for their team' do
      allow(IdentityConfig.store).to receive(:prod_like_env).and_return(false)
      members_prod_config = create(:service_provider, :with_prod_config, team: team0, user: user2)
      members_sandbox_config = create(:service_provider, :with_sandbox, team: team0, user: user2)
      no_longer_a_member_config = create(:service_provider, user: user1, team: not_a_member_team)
      other_config = create(:service_provider)

      login_as(user1)
      visit service_providers_path

      expect(page).to have_content(members_prod_config.friendly_name)
      expect(page).to have_content(members_sandbox_config.friendly_name)
      expect(page).to_not have_content(no_longer_a_member_config.friendly_name)
      expect(page).to_not have_content(other_config.friendly_name)
    end

    scenario 'prod users can only see production configs for their team' do
      allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
      members_prod_config = create(:service_provider, :with_prod_config, team: team0, user: user2)
      members_sandbox_config = create(:service_provider, :with_sandbox, team: team0, user: user2)
      no_longer_a_member_config = create(:service_provider, user: user1, team: not_a_member_team)
      other_config = create(:service_provider)

      login_as(user1)
      visit service_providers_path

      expect(page).to have_content(members_prod_config.friendly_name)
      expect(page).to_not have_content(members_sandbox_config.friendly_name)
      expect(page).to_not have_content(no_longer_a_member_config.friendly_name)
      expect(page).to_not have_content(other_config.friendly_name)
    end
  end

  context 'Edit' do
    scenario 'user can edit a service provider that belongs to a shared team' do
      team = create(:team)
      user1 = create(:user, teams: [team])
      user2 = create(:user)
      config = create(:service_provider, ial: 2, team: team, user: user2)
      new_name = 'New Service Name'
      new_description = 'New Description'

      login_as(user1)
      visit edit_service_provider_path(config)
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
