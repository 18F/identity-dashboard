require 'rails_helper'

feature 'Users can access service providers that belong to their team' do
  let(:logingov_admin) { create(:user, :logingov_admin) }
  let(:logingov_readonly) { create(:user, :logingov_readonly) }

  context 'Index' do
    let(:team0) { create(:team) }
    let(:user1) { create(:user, teams: [team0]) }
    let(:not_a_member_team) { create(:team) }
    let(:user2) { create(:user) }
    let!(:members_prod_config) do
      create(:service_provider, :with_prod_config, team: team0, user: user2)
    end
    let!(:members_sandbox_config) do
      create(:service_provider, :with_sandbox, team: team0, user: user2)
    end
    let!(:no_longer_a_member_config) do
      create(:service_provider, user: user1, team: not_a_member_team)
    end
    let!(:other_config) { create(:service_provider) }

    before { login_as user1 }

    context 'sandbox users' do
      before do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(false)
        visit service_providers_path
      end

      scenario 'can see all configs for their team' do
        expect(page).to have_content(members_prod_config.friendly_name)
        expect(page).to have_content(members_sandbox_config.friendly_name)
        expect(page).to_not have_content(no_longer_a_member_config.friendly_name)
        expect(page).to_not have_content(other_config.friendly_name)
      end

      scenario 'see the correct table columns' do
        tables = page.find_all('.usa-table')
        prod_thead = tables[0].find('thead')
        sandbox_thead = tables[1].find('thead')

        expect(prod_thead).to have_content('Friendly name')
        expect(prod_thead).to have_content('Issuer')
        expect(prod_thead).to have_content('IAL')
        expect(prod_thead).to have_content('Cert Exp')

        expect(sandbox_thead).to have_content('Friendly name')
        expect(sandbox_thead).to have_content('Issuer')
        expect(sandbox_thead).to have_content('Accessible')
        expect(sandbox_thead).to have_content('IAL')
        expect(sandbox_thead).to have_content('Cert Exp')
      end
    end

    context 'prod users' do
      before do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
        visit service_providers_path
      end

      scenario 'can see all configs for their team' do
        expect(page).to have_content(members_prod_config.friendly_name)
        expect(page).to have_content(members_sandbox_config.friendly_name)
        expect(page).to_not have_content(no_longer_a_member_config.friendly_name)
        expect(page).to_not have_content(other_config.friendly_name)
      end

      scenario 'see the correct table columns' do
        tables = page.find('.usa-table')
        prod_thead = tables.find('thead')

        expect(prod_thead).to have_content('Friendly name')
        expect(prod_thead).to have_content('Issuer')
        expect(prod_thead).to have_content('IAL')
        expect(prod_thead).to have_content('Cert Exp')
      end
    end
  end

  context 'All' do
    let(:team0) { create(:team) }
    let(:user1) { create(:user, teams: [team0]) }
    let!(:members_prod_config) do
      create(:service_provider, :with_prod_config, team: team0, user: user1)
    end
    let!(:members_sandbox_config) do
      create(:service_provider, :with_sandbox, team: team0, user: user1)
    end

    context 'on sandbox' do
      before do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(false)
      end

      scenario 'login.gov admins can see Publish service providers button' do
        login_as(logingov_admin)
        visit service_providers_all_path

        expect(page).to have_button(I18n.t('forms.buttons.trigger_idp_refresh'))
      end

      scenario 'login.gov readonly can not see Publish service providers button' do
        login_as(logingov_readonly)
        visit service_providers_all_path

        expect(page).to_not have_button(I18n.t('forms.buttons.trigger_idp_refresh'))
      end

      scenario 'Login staff sees the correct table columns' do
        login_as(logingov_readonly)
        visit service_providers_all_path

        tables = page.find_all('.usa-table')
        prod_thead = tables[0].find('thead')
        sandbox_thead = tables[1].find('thead')

        expect(prod_thead).to have_content('Friendly name')
        expect(prod_thead).to have_content('Issuer')
        expect(prod_thead).to have_content('IAL')
        expect(prod_thead).to have_content('Cert Exp')

        expect(sandbox_thead).to have_content('Friendly name')
        expect(sandbox_thead).to have_content('Issuer')
        expect(sandbox_thead).to have_content('Accessible')
        expect(sandbox_thead).to have_content('IAL')
        expect(sandbox_thead).to have_content('Cert Exp')
      end
    end

    context 'on production' do
      before do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
      end

      scenario 'login.gov admins can not see Publish service providers button' do
        login_as(logingov_admin)
        visit service_providers_all_path

        expect(page).to_not have_button(I18n.t('forms.buttons.trigger_idp_refresh'))
      end

      scenario 'login.gov readonly can not see Publish service providers button' do
        login_as(logingov_readonly)
        visit service_providers_all_path

        expect(page).to_not have_button(I18n.t('forms.buttons.trigger_idp_refresh'))
      end

      scenario 'Login staff sees the correct table columns' do
        login_as(logingov_readonly)
        visit service_providers_all_path

        tables = page.find('.usa-table')
        prod_thead = tables.find('thead')

        expect(prod_thead).to have_content('Friendly name')
        expect(prod_thead).to have_content('Issuer')
        expect(prod_thead).to have_content('IAL')
        expect(prod_thead).to have_content('Cert Exp')
        expect(prod_thead).to have_content('Created')
      end
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

      expect(page).to have_content(I18n.t('notices.service_providers_refreshed'))
      expect(page).to have_content(new_name)
      expect(page).to have_content(new_description)
      expect(page).to have_content('last_name')
    end
  end
end
