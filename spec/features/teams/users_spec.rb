require 'rails_helper'

describe 'users' do
  let(:user_team_member) { create(:user_team) }
  let(:team_member) { user_team_member.user }
  let(:other_user_team_member) { create(:user_team) }
  let(:other_team_member) { other_user_team_member.user }
  let(:team) { create(:team) }
  let(:admin_user) { create(:admin) }
  let(:user) { create(:user) }

  before do
    team.user_teams = [user_team_member, other_user_team_member]
    team.save!
  end

  feature 'add team user page access' do

    scenario 'access permitted to team member', versioning: true do
      login_as team_member
      visit new_team_user_path(team)
      expect(page).to have_content('Add new user')
    end

    scenario 'access permitted to admin', versioning: true do
      login_as admin_user
      visit new_team_user_path(team)
      expect(page).to have_content('Add new user')
    end

    scenario 'access denied to non-team member', versioning: true do
      login_as user
      visit new_team_user_path(team)
      expect(page).to have_content('Unauthorized')
    end
  end

  feature 'add team users' do

    before do
      login_as team_member
      visit new_team_user_path(Team.find(team_member.teams.first.id))
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
      fill_in 'Email', with: other_team_member.email
      click_on 'Add'
      expect(page).to have_content('This user is already a member of the team.')
    end

    scenario 'team member adds existing user not member of team', versioning: true do
      fill_in 'Email', with: user.email
      click_on 'Add'
      expect(page).to have_content(I18n.t('teams.users.create.success', email: user.email))
      team_member_emails = team.reload.users.map(&:email)
      expect(team_member_emails).to include(user.email)
    end

  end

  feature 'remove team user page access' do

    scenario 'access denied to self', versioning: true do
      login_as team_member
      visit team_remove_confirm_path(team, team_member)
      expect(page).to have_content('Unauthorized')
    end

    scenario 'access denied to non-team member', versioning: true do
      login_as user
      visit team_remove_confirm_path(team, team_member)
      expect(page).to have_content('Unauthorized')
    end

    scenario 'access permitted to admin', versioning: true do
      login_as admin_user
      visit team_remove_confirm_path(team, team_member)
      expect(page).to have_content(I18n.t('teams.users.remove.confirm_title',
                                          email:team_member.email, team:team))
    end

    scenario 'access permitted to team member to remove other team member', versioning: true do
      login_as team_member
      visit team_remove_confirm_path(team, other_team_member)
      expect(page).to have_content(I18n.t('teams.users.remove.confirm_title',
                                          email:other_team_member.email, team:team))
    end
  end

  feature 'remove team users' do

    before do
      login_as team_member
      visit team_remove_confirm_path(team, other_team_member)
    end

    scenario 'team member clicks cancel', versioning: true do
      expect(page).to have_content(I18n.t('teams.users.remove.confirm_title',
                                          email:other_team_member.email, team:team))
      click_on 'Cancel'
      expect(current_path).to eq(team_users_path(team))
      expect(page).to have_content(other_team_member.email)
    end

    scenario 'team member removes user', versioning: true do
      expect(page).to have_content(I18n.t('teams.users.remove.confirm_title',
                                          email:other_team_member.email, team:team))
      click_on I18n.t('teams.users.remove.button')
      expect(current_path).to eq(team_users_path(team))
      expect(page).to have_content(I18n.t('teams.users.remove.success',
                                          email:other_team_member.email))
    end
  end

  feature 'manage users page' do
  
    scenario 'access denied to non-team member', versioning: true do
      login_as user
      visit team_users_path(team)
      expect(page).to have_content('Unauthorized')
    end

    scenario 'access permitted to admin', versioning: true do
      login_as admin_user
      visit team_users_path(team)
      expect(page).to have_content("Manage users for #{team.name}")
    end

    scenario 'access permitted to team member to remove other team member', versioning: true do
      login_as team_member
      visit team_users_path(team)
      expect(page).to have_content("Manage users for #{team.name}")
    end

    scenario 'lists users', versioning: true do
      login_as team_member
      visit team_users_path(team)
      expect(page).to have_content("Manage users for #{team.name}")
      expect(page).to have_content(team_member.email)
      expect(page).to have_content(other_team_member.email)
    end

    scenario 'delete button only present for other team member', versioning: true do
      login_as team_member
      visit team_users_path(team)
      expect(page.all('a', text: 'Delete').length).to eq(1)
      click_on 'Delete'
      expect(page).to have_current_path(team_remove_confirm_path(team.id, other_team_member.id),
                                        ignore_query: true)
    end

    scenario 'add user button goes to add user page', versioning: true do
      login_as team_member
      visit team_users_path(team)
      click_on 'Add user'
      expect(page).to have_current_path(new_team_user_path(team.id), ignore_query: true)
    end

    scenario 'back button goes to team details page', versioning: true do
      login_as team_member
      visit team_users_path(team)
      click_on 'Back'
      expect(page).to have_current_path(team_path(team.id), ignore_query: true)
    end
  end
end
