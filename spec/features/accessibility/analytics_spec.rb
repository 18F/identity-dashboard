require 'rails_helper'
require 'axe-rspec'

feature 'Analytics page', :js do
  context 'with analytics available' do
    let(:logingov_admin) { create(:user, :logingov_admin) }
    let(:sp) do
      create(
        :service_provider,
        issuer: 'urn:gov:gsa:openidconnect.profiles:sp:sso:dol_test',
        team: logingov_admin.teams.sample,
      )
    end

    # Currently analytics are only availble to Login.gov Admins
    before do
      allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
      login_as(logingov_admin)
    end

    it 'is accessible' do
      expect(sp).to be_valid
      visit analytics_path
      expect(page).to have_link('Export report as CSV')

      # Assert charts have rendered

      expect_page_to_have_no_accessibility_violations(page)
    end
  end
end
