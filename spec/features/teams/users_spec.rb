require 'rails_helper'

feature 'add team user page access', :js do
  let(:team) { create(:team) }

  scenario 'access permitted to team member', versioning: true do
    user = create(:user, teams: [team])
    login_as user
    visit team_users_path(team)+'/new'
    expect(page).to have_content('Add New user')
  end

  scenario 'access permitted to admin', versioning: true do
    user = create(:user, teams: [])
    user.admin = true
    login_as user
    visit team_users_path(team)+'/new'
    expect(page).to have_content('Add New user')
  end

  scenario 'access denied to non-team member', versioning: true do
    user = create(:user, teams: [])
    login_as user
    visit team_users_path(team)+'/new'
    expect(page).to have_content('Unauthorized')
  end
end

feature 'add team users', :js do
  let(:team) { create(:team) }
  let(:team_member) { create(:user, teams: [team]) }

  before do
    login_as team_member
    visit team_users_path(team)+'/new'
  end

  scenario 'team member adds new user', versioning: true do
    email_to_add = 'new_user@example.com'
    fill_in 'Email', with: email_to_add
    click_on 'Add'
    expect(page).to have_content(I18n.t('teams.users.create.success', email: email_to_add))
    team_member_emails = team.reload.users.map(&:email)
    expect(team_member_emails).to include(email_to_add)
  end

  scenario 'team member adds existing member of team', versioning: true do
    other_team_member = create(:user, teams: [team])
    fill_in 'Email', with: other_team_member.email
    click_on 'Add'
    expect(page).to have_content('This user is already a member of the team.')
  end

  scenario 'team member adds existing user not member of team', versioning: true do
    existing_user = create(:user)
    fill_in 'Email', with: existing_user.email
    click_on 'Add'
    expect(page).to have_content(I18n.t('teams.users.create.success', email: existing_user.email))
    team_member_emails = team.reload.users.map(&:email)
    expect(team_member_emails).to include(existing_user.email)
  end

end

feature 'remove team user page access', :js do
  let(:team) { create(:team) }

  scenario 'access denied to self', versioning: true do
    team_member = create(:user, teams: [team])
    login_as team_member
    visit team_user_path(team, team_member)+'/remove_confirm'
    expect(page).to have_content('Unauthorized')
  end

  scenario 'access denied to non-team member', versioning: true do
    non_team_member = create(:user, teams: [])
    team_member = create(:user, teams: [team])
    login_as non_team_member
    visit team_user_path(team, team_member)+'/remove_confirm'
    expect(page).to have_content('Unauthorized')
  end

  scenario 'access permitted to admin', versioning: true do
    user = create(:user, teams: [])
    user.admin = true
    team_member = create(:user, teams: [team])
    login_as user
    visit team_user_path(team, team_member)+'/remove_confirm'
    expect(page).to have_content(I18n.t('teams.users.remove.confirm_title',
                                        email:team_member.email, team:team))
  end

  scenario 'access permitted to team member to remove other team member', versioning: true do
    team_member = create(:user, teams: [team])
    other_team_member = create(:user, teams: [team])
    login_as team_member
    visit team_user_path(team, other_team_member)+'/remove_confirm'
    expect(page).to have_content(I18n.t('teams.users.remove.confirm_title',
                                        email:other_team_member.email, team:team))
  end
end

feature 'remove team users', :js do
  let(:team) { create(:team) }
  let(:team_member) { create(:user, teams: [team]) }
  let(:other_team_member) { create(:user, teams: [team]) }

  before do
    login_as team_member
    visit team_user_path(team, other_team_member)+'/remove_confirm'
  end

  scenario 'team member clicks cancel', versioning: true do
    expect(page).to have_content(I18n.t('teams.users.remove.confirm_title',
                                        email:other_team_member.email, team:team))
    click_on 'Cancel'
    expect(current_path).to eq(team_path(team))
    expect(page).to have_content(other_team_member.email)
  end

  scenario 'team member removes user', versioning: true do
    visit team_user_path(team, other_team_member)+'/remove_confirm'
    expect(page).to have_content(I18n.t('teams.users.remove.confirm_title',
                                        email:other_team_member.email, team:team))
    click_on I18n.t('teams.users.remove.button')
    expect(current_path).to eq(team_path(team))
    expect(page).to have_content(I18n.t('teams.users.remove.success', email:other_team_member.email))
  end
end
