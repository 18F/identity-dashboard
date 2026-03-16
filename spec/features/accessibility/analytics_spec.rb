require 'rails_helper'
require 'axe-rspec'

feature 'Analytics pages', :js do
  context 'with analytics available' do
    let(:logingov_admin) { create(:user, :logingov_admin) }
    let(:sp) { create(:service_provider) }

    # Currently analytics are only availble to Login.gov Admins
    before do
      login_as(logingov_admin)
    end

    it 'is accessible' do
      visit analytics_path(sp)
      # Assert charts have rendered
      expect(page.body).to include('Completed IAL1 MFA')
      # Hover over a chart that currently has the download link enabled
      find('#chart-1').hover

      expect_page_to_have_no_accessibility_violations(page)
    end
  end
end
