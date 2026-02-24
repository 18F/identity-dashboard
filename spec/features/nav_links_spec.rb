require 'rails_helper'

feature 'Nav links' do
  let(:logingov_admin) { create(:user, :logingov_admin) }
  let(:logingov_readonly) { create(:user, :logingov_readonly) }
  let(:user) { create(:user, :partner_sample, :team_member) }

  context 'on all envs' do
    before do
      allow(IdentityConfig.store).to receive(:prod_like_env).and_return([true, false].sample)
    end

    context 'when login.gov admin' do
      before do
        login_as(logingov_admin)
        visit root_path
      end

      scenario 'should see a configurations page link' do
        expect(page).to have_link('Configurations')
      end

      scenario 'should see a teams page link' do
        expect(page).to have_link('Teams')
      end

      scenario 'should see a security events page link' do
        expect(page).to have_link('Security Events')
      end

      describe 'the Tools menu' do
        scenario 'should show a SAML validation tool link' do
          expect(page).to have_link('SAML Request Validation')
        end
      end

      describe 'the Admin menu' do
        scenario 'should show an All configurations link' do
          expect(page).to have_link('All configurations')
        end

        scenario 'should show a Users link' do
          expect(page).to have_link('Users')
        end

        scenario 'should show an All teams link' do
          expect(page).to have_link('All teams')
        end

        scenario 'should show an All security events link' do
          expect(page).to have_link('All security events')
        end

        scenario 'should show a Banner messages link' do
          expect(page).to have_link('Banner messages')
        end

        scenario 'should show a Your API auth token' do
          expect(page).to have_link('Your API auth token')
        end

        scenario 'should show a Deleted configurations' do
          expect(page).to have_link('Deleted configurations')
        end

        scenario 'should show a User permissions report link' do
          expect(page).to have_link('User permissions report')
        end
      end

      scenario 'should see a sign out page link' do
        expect(page).to have_link('Sign out')
      end
    end

    context 'when login.gov readonly' do
      before do
        login_as(logingov_readonly)
        visit root_path
      end

      scenario 'should see a configurations page link' do
        expect(page).to have_link('Configurations')
      end

      scenario 'should see a teams page link' do
        expect(page).to have_link('Teams')
      end

      scenario 'should not see a security events page link' do
        # this is negative because login_readonly should not be part
        # of any teams that have configurations.
        expect(page).to_not have_link('Security Events')
      end

      describe 'the Tools menu' do
        scenario 'should show a SAML validation tool link' do
          expect(page).to have_link('SAML Request Validation')
        end
      end

      describe 'the Admin menu' do
        scenario 'should show an All configurations link' do
          expect(page).to have_link('All configurations')
        end

        scenario 'should show a Users link' do
          expect(page).to have_link('Users')
        end

        scenario 'should show an All teams link' do
          expect(page).to have_link('All teams')
        end

        scenario 'should show an All security events link' do
          expect(page).to have_link('All security events')
        end

        scenario 'should show a Banner messages link' do
          expect(page).to have_link('Banner messages')
        end

        scenario 'should not show a Your API auth token' do
          expect(page).to_not have_link('Your API auth token')
        end

        scenario 'should show a Deleted configurations' do
          expect(page).to have_link('Deleted configurations')
        end

        scenario 'should show a User permissions report link' do
          expect(page).to have_link('User permissions report')
        end

        scenario 'should not show a Configuration extraction link' do
          expect(page).to_not have_link('Configuration extraction')
        end

        scenario 'should not show a Connect with Airtable link' do
          expect(page).to_not have_link('Connect with Airtable')
        end
      end

      scenario 'should see a sign out page link' do
        expect(page).to have_link('Sign out')
      end
    end
  end

  context 'on production environments' do
    before do
      allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
    end

    context 'when login.gov admin' do
      before do
        login_as(logingov_admin)
        visit root_path
      end

      describe('the Admin menu') do
        scenario 'should show a Connect with Airtable link' do
          expect(page).to have_link('Connect with Airtable')
        end

        scenario 'should not show a Configuration extraction link' do
          expect(page).to_not have_link('Configuration extraction')
        end
      end
    end
  end

  context 'on sandbox environments' do
    before do
      allow(IdentityConfig.store).to receive(:prod_like_env).and_return(false)
    end

    context 'when logingov_admin' do
      before do
        login_as(logingov_admin)
        visit root_path
      end

      describe('the Admin menu') do
        scenario 'should show a Configuration extraction link' do
          expect(page).to have_link('Configuration extraction')
        end

        scenario 'should not show a Connect with Airtable link' do
          expect(page).to_not have_link('Connect with Airtable')
        end
      end
    end
  end

  context 'when signed in as a partner' do
    before do
      allow(IdentityConfig.store).to receive(:prod_like_env).and_return([true, false].sample)
      login_as(user)
      visit root_path
    end

    scenario 'should see a configurations page link' do
      expect(page).to have_link('Configurations')
    end

    scenario 'should see a teams page link' do
      expect(page).to have_link('Teams')
    end

    scenario 'should not see a security events page link' do
      expect(page).to_not have_link('Security Events')
    end

    describe 'the Tools menu' do
      scenario 'should show a SAML validation tool link' do
        expect(page).to have_link('SAML Request Validation')
      end
    end

    describe 'the Admin menu' do
      scenario 'should not show an All configurations link' do
        expect(page).to_not have_link('All configurations')
      end

      scenario 'should not show a Users link' do
        expect(page).to_not have_link('Users')
      end

      scenario 'should not show an All teams link' do
        expect(page).to_not have_link('All teams')
      end

      scenario 'should not show an All security events link' do
        expect(page).to_not have_link('All security events')
      end

      scenario 'should not show a Banner messages link' do
        expect(page).to_not have_link('Banner messages')
      end

      scenario 'should not show a Your API auth token' do
        expect(page).to_not have_link('Your API auth token')
      end

      scenario 'should not show a Deleted configurations' do
        expect(page).to_not have_link('Deleted configurations')
      end

      scenario 'should not show a User permissions report link' do
        expect(page).to_not have_link('User permissions report')
      end

      scenario 'should not show a Configuration extraction link' do
        expect(page).to_not have_link('Configuration extraction')
      end

      scenario 'should not show a Connect with Airtable link' do
        expect(page).to_not have_link('Connect with Airtable')
      end
    end

    scenario 'should see a sign out page link' do
      expect(page).to have_link('Sign out')
    end
  end
end
