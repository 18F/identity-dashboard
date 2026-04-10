require 'rails_helper'
require 'axe-rspec'

feature 'Analytics page', :js do
  context 'with analytics available' do
    let(:logingov_admin) { create(:user, :logingov_admin) }
    let(:sp) { create(:service_provider) }

    # Currently analytics are only availble to Login.gov Admins
    before do
      allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
      login_as(logingov_admin)
    end

    it 'is accessible' do
      visit analytics_path
      # Assert charts have rendered
      expect(page.body).to include('Reports')

      expect_page_to_have_no_accessibility_violations(page)
    end
  end
end
