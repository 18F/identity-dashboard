require 'rails_helper'

feature 'manage users', :js do
  scenario 'removing users by email address', versioning: true do
    team = create(:team)
    user = create(:user, teams: [team])
    user_to_remove = create(:user, teams: [team])

    login_as user
    visit team_path(team)
    click_on 'Manage users'

    remove_email_link = page.
                        find('li', text: "#{user_to_remove.email} | ⨉").
                        find('a', text: '⨉')
    remove_email_link.click

    expect(page).to_not have_content(user_to_remove.email)

    click_on 'Save'

    team_member_emails = team.reload.users.map(&:email)

    expect(team_member_emails).to include(user.email)
    expect(team_member_emails).to_not include(user_to_remove.email)
    # auditing!
    expect(PaperTrail::Version.where(event: 'destroy', item_type: 'UserTeam').count).to eq(1)
  end
end
