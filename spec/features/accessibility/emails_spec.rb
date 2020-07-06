require 'rails_helper'

feature 'Email pages', :js do
  let(:admin) { create(:admin) }

  before do
    login_as(admin)
  end

  scenario 'index page is accessible' do
    visit emails_path
    expect(page).to be_accessible
  end
end
