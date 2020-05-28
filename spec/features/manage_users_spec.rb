require 'rails_helper'

feature 'manage users', :js do
  scenario 'adding and removing users by email address' do
    team = create(:team)
    user = create(:user, teams: [team])
    user_to_remove = create(:user, teams: [team])
    email_to_add = 'new_user@example.com'

    login_as user
    visit team_path(team)
    click_on 'Manage users'

    remove_email_link = page.
                        find('li', text: "#{user_to_remove.email} | ⨉").
                        find('a', text: '⨉')
    remove_email_link.click

    expect(page).to_not have_content(user_to_remove.email)

    fill_in 'Email', with: email_to_add
    click_on 'Add user'

    expect(page).to have_content(email_to_add)

    click_on 'Save'

    team_member_emails = team.reload.users.map(&:email)

    expect(team_member_emails).to include(user.email)
    expect(team_member_emails).to include(email_to_add)
    expect(team_member_emails).to_not include(user_to_remove.email)
  end

  scenario 'adding a user with an invalid email address renders an error' do
    team = create(:team)
    user = create(:user, teams: [team])

    login_as user
    visit team_path(team)
    click_on 'Manage users'

    fill_in 'Email', with: 'Nonsense'
    click_on 'Add user'

    expect(page).to have_content('Nonsense | ⨉')

    click_on 'Save'

    expect(page).to have_content('nonsense is not a valid email address')
  end
end
