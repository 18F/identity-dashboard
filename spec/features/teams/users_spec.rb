require 'rails_helper'

describe 'users' do
  let(:team_member_membership) { create(:user_team) }
  let(:team_member) { team_member_membership.user }
  let(:other_team_member_membership) { create(:user_team) }
  let(:other_team_member) { other_team_member_membership.user }
  let(:team) { create(:team) }
  let(:partner_admin_membership) { create(:user_team, :partner_admin, team:) }
  let(:partner_admin_team_member) { partner_admin_membership.user }
  let(:readonly_membership) { create(:user_team, :partner_readonly, team:) }
  let(:readonly_team_member) { readonly_membership.user }
  let(:logingov_admin) { create(:logingov_admin) }
  let(:user) { create(:user) }

  before do
    team.user_teams = [team_member_membership, other_team_member_membership]
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
      visit new_team_user_path(team)
      expect(page).to have_content('Add new user')
    end

    scenario 'access permitted to login.gov admin (without RBAC)' do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
      login_as logingov_admin
      visit new_team_user_path(team)
      expect(page).to have_content('Add new user')
    end

    scenario 'access permitted to login.gov admin' do
      login_as logingov_admin
      visit new_team_user_path(team)
      expect(page).to have_content('Add new user')
    end

    scenario 'access denied to partner read-only' do
      login_as readonly_team_member
      visit new_team_user_path(team)
      expect(page).to have_content('Unauthorized')
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

  feature 'add users to a team' do
    before do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(true)
      login_as partner_admin_team_member
      visit new_team_user_path(Team.find(team_member.teams.first.id))
    end

    scenario 'team member adds new user' do
      email_to_add = 'new_user@example.com'
      fill_in 'Email', with: email_to_add
      click_on 'Add'
      expect(page).to have_content(I18n.t('teams.users.create.success', email: email_to_add))
      new_membership = UserTeam.find_by(user: User.find_by(email: email_to_add), team: team)
      expect(new_membership.role.name).to eq('partner_readonly')
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
      new_membership = UserTeam.find_by(user: User.find_by(email: user.email), team: team)
      expect(new_membership.role.name).to eq('partner_readonly')
    end

    scenario 'add a user not yet in the system' do
      random_email = "random_user_#{rand(1..1000)}@gsa.gov"
      fill_in 'Email', with: random_email
      click_on 'Add'
      expect(page).to have_content(I18n.t('teams.users.create.success', email: random_email))
      team_member_emails = team.reload.users.map(&:email)
      expect(team_member_emails).to include(random_email)
    end
  end

  describe 'login.gov admin with an empty team' do
    let(:empty_team) { create(:team) }

    before do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(true)
      login_as logingov_admin
      visit new_team_user_path(empty_team)
    end

    it 'defaults new users to the Partner Admin role' do
      expect(empty_team.users.count).to be 0
      random_email = "random_user_#{rand(1..1000)}@gsa.gov"
      fill_in 'Email', with: random_email
      click_on 'Add'
      expect(page).to have_content(I18n.t('teams.users.create.success', email: random_email))
      new_membership = UserTeam.find_by(user: User.find_by(email: random_email), team: empty_team)
      expect(new_membership.role.name).to eq('partner_admin')
    end
  end

  feature 'remove team user page access' do
    scenario 'access permitted to team member to remove other team member (without RBAC)' do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
      login_as team_member
      visit team_remove_confirm_path(team, other_team_member)
      expect(page).to have_content(I18n.t('teams.users.remove.confirm_title',
                                          email: other_team_member.email, team: team))
    end

    scenario 'access permitted to partner admin team member to remove other team member' do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(true)
      login_as partner_admin_team_member
      visit team_remove_confirm_path(team, other_team_member)
      expect(page).to have_content(I18n.t('teams.users.remove.confirm_title',
                                          email: other_team_member.email, team: team))
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
                                          email: other_team_member.email, team: team))
      click_on 'Cancel'
      expect(page).to have_current_path(team_users_path(team))
      expect(page).to have_content(other_team_member.email)
    end

    scenario 'team member removes user' do
      expect(page).to have_content(I18n.t('teams.users.remove.confirm_title',
                                          email: other_team_member.email, team: team))
      click_on I18n.t('teams.users.remove.button')
      expect(page).to have_current_path(team_users_path(team))
      expect(page).to have_content(I18n.t('teams.users.remove.success',
                                          email: other_team_member.email))
    end
  end

  feature 'remove team users' do
    before do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(true)
      login_as partner_admin_team_member
      visit team_remove_confirm_path(team, other_team_member)
    end

    scenario 'team member clicks cancel' do
      expect(page).to have_content(I18n.t('teams.users.remove.confirm_title',
                                          email: other_team_member.email, team: team))
      click_on 'Cancel'
      expect(page).to have_current_path(team_users_path(team))
      expect(page).to have_content(other_team_member.email)
    end

    scenario 'team member removes user' do
      expect(page).to have_content(I18n.t('teams.users.remove.confirm_title',
                                          email: other_team_member.email, team: team))
      click_on I18n.t('teams.users.remove.button')
      expect(page).to have_current_path(team_users_path(team))
      expect(page).to have_content(I18n.t('teams.users.remove.success',
                                          email: other_team_member.email))
    end
  end

  feature 'manage users page' do
    scenario 'access denied to non-team member' do
      login_as user
      visit team_users_path(team)
      expect(page).to have_content('Unauthorized')
    end

    scenario 'access permitted to login.gov admin' do
      login_as logingov_admin
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

    scenario 'lists users even with an old, bugged user removal' do
      bad_membership = create(:user_team, team:)
      bad_membership.update_attribute(:user_id, nil)
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
      expect(find_all('a', text: 'Delete').count).to eq(1)
      click_on 'Delete'
      expect(page).to have_current_path(team_remove_confirm_path(team.id, other_team_member.id))
    end

    scenario 'delete button only present for another team member who is a Partner Admin' do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(true)
      login_as team_member
      visit team_users_path(team)
      expect(find_all('a', text: 'Delete').count).to eq(0)

      login_as partner_admin_team_member
      visit team_users_path(team)
      # two users: `team_member` and `other_team_member`
      expect(find_all('a', text: 'Delete').count).to eq(2)
      find_all('a', text: 'Delete').first.click
      expect(page).to have_current_path(team_remove_confirm_path(team.id, team_member.id))
    end

    scenario 'add user button goes to add user page' do
      login_as partner_admin_team_member
      visit team_users_path(team)
      click_on 'Add user'
      expect(page).to have_current_path(new_team_user_path(team.id))
    end

    scenario 'back button goes to team details page' do
      login_as partner_admin_team_member
      visit team_users_path(team)
      click_on 'Back'
      expect(page).to have_current_path(team_path(team.id))
    end
  end

  feature 'modifying team user permissions' do
    context 'when login.gov admin' do
      before { login_as logingov_admin }

      it 'allows modifying any user roles' do
        team_users = [partner_admin_team_member, readonly_team_member]

        user_to_change = team_users.sample
        old_role = UserTeam.find_by(user: user_to_change, team: team).role
        new_role = (Role.all - [Role::LOGINGOV_ADMIN, old_role]).sample

        user_to_not_change = (team_users - [user_to_change]).first
        expected_unchanged_role = UserTeam.find_by(user: user_to_not_change, team: team).role

        visit team_users_path(team)

        within('tr', text: user_to_change.email) do
          click_on 'Edit'
        end
        choose new_role.friendly_name
        click_on 'Update'
        user_to_change.reload
        actual_role = UserTeam.find_by(user: user_to_change, team: team).role
        expect(actual_role).to eq(new_role)
        user_to_not_change.reload
        actual_unchanged_role = UserTeam.find_by(user: user_to_not_change, team: team).role
        expect(actual_unchanged_role).to eq(expected_unchanged_role)
      end
    end

    context 'when partner admin' do
      before { login_as partner_admin_team_member }

      it 'does not show edit button for self' do
        editable_user = [team_member, readonly_team_member].sample

        visit team_users_path(team)

        within('tr', text: editable_user.email) do
          expect(self).to have_link('Edit')
        end
        within('tr', text: partner_admin_team_member.email) do
          expect(self).to_not have_link('Edit')
        end
      end

      it 'does show all roles except for login.gov admin role' do
        visit edit_team_user_path(team, team_member)
        input_item_strings = find_all(:xpath, '//li[.//input]').map(&:text)
        expected_roles = (Role.all - [Role::LOGINGOV_ADMIN])
        expect(input_item_strings.count).to eq(expected_roles.count)
        expected_roles.each_with_index do |role, index|
          expect(input_item_strings[index]).to include(role.friendly_name)
        end
        expect(page).to_not have_content(Role::LOGINGOV_ADMIN.friendly_name)
      end
    end
  end
end
