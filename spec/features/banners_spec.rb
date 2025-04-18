require 'rails_helper'

feature 'Banners' do
  let(:current_banner) do
    build(:banner, message: 'A banner, with a <a href="banner_test_link">link</a>',
                   start_date: Time.zone.now.beginning_of_day - 2.days,
                   end_date: Time.zone.now.beginning_of_day + 2.days)
  end
  let(:script_banner) do
    build(:banner, message: '<script>alert("alert")</script>',
                   start_date: Time.zone.now.beginning_of_day - 2.days,
                   end_date: Time.zone.now.beginning_of_day + 2.days)
  end

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
      expect(page).to have_css("a[href='banner_test_link']")
      expect(page).to_not have_content('<script>alert("alert")</script>')
    end
  end

  scenario 'html renders in banners admin table' do
    logingov_admin = create(:user, :logingov_admin)
    login_as(logingov_admin)

    visit banners_path

    expect(page).to have_css("th > a[href='banner_test_link']")
  end

  context 'it displays at the approptiate start time' do
    before do
      allow(Time).to receive(:now).and_return(Time.zone.now.beginning_of_day - 2.days + 1.second)
      visit root_path
    end

    it 'displays the banner' do
      expect(page).to have_css('.usa-alert')
    end
  end

  context 'it does not display at the before the start time' do
    before do
      allow(Time).to receive(:now).and_return(Time.zone.now.beginning_of_day - 3.days)
      visit root_path
    end

    it 'does not display the banner' do
      expect(page).to_not have_css('.usa-alert')
    end
  end

  context 'it displays at the approptiate end time' do
    before do
      allow(Time).to receive(:now).and_return(Time.zone.now.beginning_of_day + 2.days - 1.second)
      visit root_path
    end

    it 'displays the banner' do
      expect(page).to have_css('.usa-alert')
    end
  end

  context 'it does not display at the before the start time' do
    before do
      allow(Time).to receive(:now).and_return(Time.zone.now.beginning_of_day + 3.days)
      visit root_path
    end

    it 'does not display the banner' do
      expect(page).to_not have_css('.usa-alert')
    end
  end
end
