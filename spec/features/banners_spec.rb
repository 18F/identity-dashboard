require 'rails_helper'

feature 'Banners' do
  let(:current_banner) {
    build(:banner, message: 'A banner, with a <a href="banner_test_link">link</a>',
                   start_date: Time.zone.now.beginning_of_day - 2.days,
                   end_date: Time.zone.now.beginning_of_day + 2.days)
  }
  let(:script_banner) {
    build(:banner, message: '<script>alert("alert")</script>',
                   start_date: Time.zone.now.beginning_of_day - 2.days,
                   end_date: Time.zone.now.beginning_of_day + 2.days)
  }

  before do
    current_banner.save
    script_banner.save
  end

  context 'html renders in banners' do
    before do
      visit root_path
    end

    it 'renders html' do
      expect(page).to have_css('.usa-alert')
      expect(page).to have_selector("a[href='banner_test_link']")
      expect(page).to_not have_content('<script>alert("alert")</script>')
    end
  end

  scenario 'html renders in banners admin table' do
    admin = create(:admin)
    login_as(admin)

    visit banners_path

    expect(page).to have_selector("th > a[href='banner_test_link']")
  end
end