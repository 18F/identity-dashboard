require 'rails_helper'

feature 'add team user page access', :js do
  scenario 'access permitted to team member', versioning: true do
    team = create(:team)
    user = create(:user, teams: [team])
    login_as user
    visit team_users_path(team)+'/new'
    expect(page).to have_content('Add New user')
  end

  scenario 'access permitted to admin', versioning: true do
    team = create(:team)
    user = create(:user, teams: [])
    user.admin = true
    login_as user
    visit team_users_path(team)+'/new'
    expect(page).to have_content('Add New user')
  end

  scenario 'access denied to non-team member', versioning: true do
    team = create(:team)
    user = create(:user, teams: [])
    login_as user
    visit team_users_path(team)+'/new'
    expect(page).to have_content('Unauthorized')
  end
end

feature 'add team users', :js do
  scenario 'team member adds new user', versioning: true do
    team = create(:team)
    user = create(:user, teams: [team])
    user_to_remove = create(:user, teams: [team])
    email_to_add = 'new_user@example.com'

    login_as user
    visit team_users_path(team)+'/new'
    fill_in 'Email', with: email_to_add
    click_on 'Add'
    expect(page).to have_content(I18n.t('teams.users.create.success', email: email_to_add))
    team_member_emails = team.reload.users.map(&:email)
    expect(team_member_emails).to include(email_to_add)
  end

  scenario 'team member adds existing user', versioning: true do
    team = create(:team)
    user = create(:user, teams: [team])
    user_to_remove = create(:user, teams: [team])
    email_to_add = 'new_user@example.com'

    login_as user
    visit team_users_path(team)+'/new'
    fill_in 'Email', with: email_to_add
    click_on 'Add'
    visit team_users_path(team)+'/new'
    fill_in 'Email', with: email_to_add
    click_on 'Add'
    expect(page).to have_content(I18n.t('notices.user_already_exists', email: email_to_add))
  end

end

feature 'remove team user page access', :js do
  scenario 'access denied to self', versioning: true do
    team = create(:team)
    user = create(:user, teams: [team])
    login_as user
    visit team_user_path(team, user)+'/remove_confirm'
    expect(page).to have_content('Unauthorized')
  end

  scenario 'access denied to non-team member', versioning: true do
    team = create(:team)
    user = create(:user, teams: [])
    other_user = create(:user, teams: [team])
    login_as user
    visit team_user_path(team, other_user)+'/remove_confirm'
    expect(page).to have_content('Unauthorized')
  end

  scenario 'access permitted to admin', versioning: true do
    team = create(:team)
    user = create(:user, teams: [])
    user.admin = true
    other_user = create(:user, teams: [team])
    login_as user
    visit team_user_path(team, other_user)+'/remove_confirm'
    expect(page).to have_content(I18n.t('teams.users.remove.confirm_title',
                                        email:other_user.email, team:team))
  end

  scenario 'access permitted to team member', versioning: true do
    team = create(:team)
    user = create(:user, teams: [team])
    other_user = create(:user, teams: [team])
    login_as user
    visit team_user_path(team, other_user)+'/remove_confirm'
    expect(page).to have_content(I18n.t('teams.users.remove.confirm_title',
                                        email:other_user.email, team:team))
  end
end

feature 'remove team users', :js do
  scenario 'team member clicks cancel', versioning: true do
    team = create(:team)
    user = create(:user, teams: [team])
    other_user = create(:user, teams: [team])
    login_as user
    visit team_user_path(team, other_user)+'/remove_confirm'
    expect(page).to have_content(I18n.t('teams.users.remove.confirm_title',
                                        email:other_user.email, team:team))
    click_on 'Cancel'
    expect(current_path).to eq(team_path(team))
    expect(page).to have_content(other_user.email)
  end

  scenario 'team member removes user', versioning: true do
    team = create(:team)
    user = create(:user, teams: [team])
    other_user = create(:user, teams: [team])
    login_as user
    visit team_user_path(team, other_user)+'/remove_confirm'
    expect(page).to have_content(I18n.t('teams.users.remove.confirm_title',
                                        email:other_user.email, team:team))
    click_on I18n.t('teams.users.remove.button')
    expect(current_path).to eq(team_path(team))
    expect(page).to have_content(I18n.t('teams.users.remove.success', email:other_user.email))
  end
end
