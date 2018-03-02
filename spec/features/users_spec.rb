require 'rails_helper'

feature 'admin manages users' do
  scenario 'manage user page accessible from nav bar link' do
    admin = create(:admin)

    login_as(admin)
    visit service_providers_path
    click_on 'Users'

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

  xscenario 'admin edits users' do
    admin = create(:admin)
    user = create(:user)

    login_as(admin)
    visit users_path
    find("a[aria-label='#{t('links.aria.edit', name: user.email)}']").click

    expect(current_path).to eq(edit_user_path(user))
    expect(page).to have_content(user.email)

    check('Admin')
    click_on 'Update'

    expect(current_path).to eq(users_path)
    expect(find('tr', text: user.email)).to have_content('true')
  end
end
