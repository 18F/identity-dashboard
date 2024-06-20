require 'rails_helper'

feature 'Banners' do
  context 'html renders in banners' do
    let(:current_banner) {
      build(:banner, message: 'A banner, with a <a href="banner_test_link">link</a>',
                     start_date: Time.zone.now.beginning_of_day - 2.days,
                     end_date: Time.zone.now.beginning_of_day + 2.days)
    }
    before do
      current_banner.save
      visit root_path
    end

    it 'renders html' do
      expect(page).to have_css('.usa-alert')
      expect(page).to have_selector("a[href='banner_test_link']")
    end
  end
end