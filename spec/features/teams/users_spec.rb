require 'rails_helper'

describe 'users' do
  let(:user_team_member) { create(:user_team) }
  let(:team_member) { user_team_member.user }
  let(:other_user_team_member) { create(:user_team) }
  let(:other_team_member) { other_user_team_member.user }
  let(:team) { create(:team) }
  let(:partner_admin_access) { create(:user_team, team:, role: Role.find('Partner Admin'))}
  let(:partner_admin_team_member) { partner_admin_access.user }
  let(:admin_user) { create(:admin) }
  let(:user) { create(:user) }

  before do
    team.user_teams = [user_team_member, other_user_team_member]
    team.save!
  end

  feature 'add team user page access' do

    scenario 'access permitted to team member (without RBAC)' do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
      login_as team_member
      visit new_team_user_path(team)
      expect(page).to have_content('Add new user')
    end

    scenario 'access permitted to Partner Admin team member' do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(true)
      login_as partner_admin_team_member
      visit team_users_path(team)+'/new'
      expect(page).to have_content('Add new user')
    end

    scenario 'access permitted to admin (without RBAC)' do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
      login_as admin_user
      visit new_team_user_path(team)
      expect(page).to have_content('Add new user')
    end

    scenario 'access permitted to admin' do
      login_as admin_user
      visit team_users_path(team)+'/new'
      expect(page).to have_content('Add new user')
    end

    scenario 'access denied to non-team member' do
      login_as user
      visit new_team_user_path(team)
      expect(page).to have_content('Unauthorized')
    end
  end

  feature 'add team users (without RBAC)' do

    before do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
      login_as team_member
      visit new_team_user_path(Team.find(team_member.teams.first.id))
    end

    scenario 'team member adds new user' do
      email_to_add = 'new_user@example.com'
      fill_in 'Email', with: email_to_add
      click_on 'Add'
      expect(page).to have_content(I18n.t('teams.users.create.success', email: email_to_add))
      team_member_emails = team.reload.users.map(&:email)
      expect(team_member_emails).to include(email_to_add)
    end

    scenario 'team member adds existing member of team' do
      fill_in 'Email', with: other_team_member.email
      click_on 'Add'
      expect(page).to have_content('This user is already a member of the team.')
    end

    scenario 'team member adds existing user not member of team' do
      fill_in 'Email', with: user.email
      click_on 'Add'
      expect(page).to have_content(I18n.t('teams.users.create.success', email: user.email))
      team_member_emails = team.reload.users.map(&:email)
      expect(team_member_emails).to include(user.email)
    end

  end

  feature 'add team users' do

    before do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(true)
      login_as partner_admin_team_member
      visit team_users_path(Team.find(team_member.teams.first.id))+'/new'
    end

    scenario 'team member adds new user' do
      email_to_add = 'new_user@example.com'
      fill_in 'Email', with: email_to_add
      click_on 'Add'
      expect(page).to have_content(I18n.t('teams.users.create.success', email: email_to_add))
      team_member_emails = team.reload.users.map(&:email)
      expect(team_member_emails).to include(email_to_add)
    end

    scenario 'team member adds existing member of team' do
      fill_in 'Email', with: other_team_member.email
      click_on 'Add'
      expect(page).to have_content('This user is already a member of the team.')
    end

    scenario 'team member adds existing user not member of team' do
      fill_in 'Email', with: user.email
      click_on 'Add'
      expect(page).to have_content(I18n.t('teams.users.create.success', email: user.email))
      team_member_emails = team.reload.users.map(&:email)
      expect(team_member_emails).to include(user.email)
    end
  end

  feature 'remove team user page access' do
    scenario 'access permitted to team member to remove other team member (without RBAC)' do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
      login_as team_member
      visit team_remove_confirm_path(team, other_team_member)
      expect(page).to have_content(I18n.t('teams.users.remove.confirm_title',
                                          email:other_team_member.email, team:team))
    end

    scenario 'access permitted to partner admin team member to remove other team member' do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(true)
      login_as partner_admin_team_member
      visit team_remove_confirm_path(team, other_team_member)
      expect(page).to have_content(I18n.t('teams.users.remove.confirm_title',
                                          email:other_team_member.email, team:team))
    end
  end

  feature 'remove team users (without RBAC)' do

    before do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
      login_as team_member
      visit team_remove_confirm_path(team, other_team_member)
    end

    scenario 'team member clicks cancel' do
      expect(page).to have_content(I18n.t('teams.users.remove.confirm_title',
                                          email:other_team_member.email, team:team))
      click_on 'Cancel'
      expect(current_path).to eq(team_users_path(team))
      expect(page).to have_content(other_team_member.email)
    end

    scenario 'team member removes user' do
      expect(page).to have_content(I18n.t('teams.users.remove.confirm_title',
                                          email:other_team_member.email, team:team))
      click_on I18n.t('teams.users.remove.button')
      expect(current_path).to eq(team_users_path(team))
      expect(page).to have_content(I18n.t('teams.users.remove.success',
                                          email:other_team_member.email))
    end
  end

  feature 'remove team users' do

    before do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(true)
      login_as partner_admin_team_member
      visit team_user_path(team, other_team_member)+'/remove_confirm'
    end

    scenario 'team member clicks cancel' do
      expect(page).to have_content(I18n.t('teams.users.remove.confirm_title',
                                          email:other_team_member.email, team:team))
      click_on 'Cancel'
      expect(current_path).to eq(team_users_path(team))
      expect(page).to have_content(other_team_member.email)
    end

    scenario 'team member removes user' do
      expect(page).to have_content(I18n.t('teams.users.remove.confirm_title',
                                          email:other_team_member.email, team:team))
      click_on I18n.t('teams.users.remove.button')
      expect(current_path).to eq(team_users_path(team))
      expect(page).to have_content(I18n.t('teams.users.remove.success', 
                                          email:other_team_member.email))
    end
  end
  feature 'manage users page' do
  
    scenario 'access denied to non-team member' do
      login_as user
      visit team_users_path(team)
      expect(page).to have_content('Unauthorized')
    end

    scenario 'access permitted to admin' do
      login_as admin_user
      visit team_users_path(team)
      expect(page).to have_content("Manage users for #{team.name}")
    end

    scenario 'access permitted to team member to remove other team member (without RBAC)' do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
      login_as team_member
      visit team_users_path(team)
      expect(page).to have_content("Manage users for #{team.name}")
    end

    scenario 'access permitted to partner admin team member to remove other team member' do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(true)
      login_as team_member
      visit team_users_path(team)
      expect(page).to_not have_content("Manage users for #{team.name}")
      expect(page).to have_content('Unauthorized')

      login_as partner_admin_team_member
      visit team_users_path(team)
      expect(page).to have_content("Manage users for #{team.name}")
    end

    scenario 'lists users' do
      login_as partner_admin_team_member
      visit team_users_path(team)
      expect(page).to have_content("Manage users for #{team.name}")
      expect(page).to have_content(partner_admin_team_member.email)
      expect(page).to have_content(team_member.email)
      expect(page).to have_content(other_team_member.email)
    end

    scenario 'delete button only present for any other team member (without RBAC)' do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
      login_as team_member
      visit team_users_path(team)
      expect(find_all('a', text:'Delete').count).to eq(1)
      click_on 'Delete'
      expect(current_path).to eq(team_remove_confirm_path(team.id,other_team_member.id))
    end

    scenario 'delete button only present for another team member who is a Partner Admin' do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(true)
      login_as team_member
      visit team_users_path(team)
      expect(find_all('a', text:'Delete').count).to eq(0)

      login_as partner_admin_team_member
      visit team_users_path(team)
      # two users: `team_member` and `other_team_member`
      expect(find_all('a', text:'Delete').count).to eq(2)
      find_all('a', text:'Delete').first.click
      expect(current_path).to eq("#{team_user_path(team.id, team_member.id)}/remove_confirm")
    end

    scenario 'add user button goes to add user page' do
      login_as partner_admin_team_member
      visit team_users_path(team)
      click_on 'Add user'
      expect(current_path).to eq(new_team_user_path(team.id))
    end

    scenario 'back button goes to team details page' do
      login_as partner_admin_team_member
      visit team_users_path(team)
      click_on 'Back'
      expect(current_path).to eq(team_path(team.id))
    end

  end

end
