require 'rails_helper'

feature 'admin manages users' do
  scenario 'manage user page accessible from nav bar link' do
    admin = create(:admin)

    login_as(admin)
    visit service_providers_path
    click_on t('links.users')

    expect(current_path).to eq(users_path)
  end

  scenario 'user index page shows all users' do
    admin = create(:admin)
    users = create_list(:user, 3)

    login_as(admin)
    visit users_path

    users.each do |user|
      expect(page).to have_content(user.email)
      expect(page).to have_content(user.first_name)
      expect(page).to have_content(user.last_name)
    end
  end
end
