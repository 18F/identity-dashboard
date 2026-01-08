require 'rails_helper'

feature 'TeamMembership CRUD' do
  let(:logingov_admin) { create(:user, :logingov_admin) }
  let(:logingov_readonly) { create(:user, :logingov_readonly) }
  let(:gov_partner) { create(:user, email: 'test@gsa.gov') }
  let(:contractor) { create(:user, email: 'contractor@gsa.com') }

  scenario 'Create' do
    create(:agency, name: 'GSA')

    login_as(logingov_admin)
    visit new_team_path

    fill_in 'Description', with: 'department name'
    fill_in 'Name', with: 'team name'
    select('GSA', from: 'Agency')

    click_on 'Create'
    expect(page).to have_current_path(team_users_path(Team.last))
    expect(page).to have_content('Success')
    expect(page).to have_content('team name')
  end

  scenario 'Create (Login.gov Readonly)' do
    create(:agency, name: 'GSA')

    login_as(logingov_readonly)
    visit new_team_path

    expect(page).to have_content('Unauthorized')
  end

  scenario 'Create (gov user is not yet on a team)' do
    create(:agency, name: 'GSA')

    login_as(gov_partner)
    visit new_team_path

    fill_in 'Description', with: 'department name'
    fill_in 'Name', with: 'team name'
    select('GSA', from: 'Agency')

    click_on 'Create'
    expect(page).to have_current_path(team_users_path(Team.last))
    expect(page).to have_content('Success')
    expect(page).to have_content('team name')
  end

  scenario 'Create (commercial user)' do
    create(:agency, name: 'GSA')

    login_as(contractor)
    visit new_team_path

    expect(page).to have_content('Unauthorized')
  end

  context 'User already in a team' do
    scenario 'User does show up in the team membership that they are assigned to' do
      team = create(:team)
      user = create(:team_membership, :partner_developer, team:).user

      login_as(logingov_admin)
      visit edit_team_path(team)

      expect(page).to have_content(user.email)
    end

    scenario 'User can be added to another team' do
      user = create(:user)
      team1 = create(:team, users: [user])
      team2 = create(:team)

      login_as(logingov_admin)
      visit edit_team_path(team2)
      click_on 'Manage users'
      click_on 'Add user'
      fill_in 'Email', with: user.email
      click_on 'Add'
      expect(user.teams).to include(team1, team2)
    end
  end

  scenario 'Update' do
    org = create(:team)
    create(:agency, name: 'USDS')
    login_as(logingov_admin)

    visit teams_all_path
    find("a[href='#{edit_team_path(org)}']").click
    expect(page).to have_current_path(edit_team_path(org))

    fill_in 'Name', with: 'updated team'
    fill_in 'Description', with: 'updated department'
    select('USDS', from: 'Agency')
    click_on 'Update'

    expect(page).to have_current_path(teams_all_path)
    expect(page).to have_content('Success')
    expect(page).to have_content('USDS')
    expect(page).to have_content('updated department')
    expect(page).to have_content('updated team')
  end

  describe 'Index' do
    scenario 'as logingov_admin' do
      org1 = create(:team)
      org2 = create(:team)
      team = create(:team)
      sp = create(:service_provider, team:)
      user = create(:user, teams: [team])

      login_as(logingov_admin)
      visit teams_all_path

      expect(page).to have_content(org1.name)
      expect(page).to have_content(org2.name)
      expect(page).to have_content(org1.uuid)
      expect(page).to have_content(org2.uuid)
      expect(page).to have_content(org1.agency.name)
      expect(page).to have_content(org2.agency.name)
      expect(page).to have_content(org1.description)
      expect(page).to have_content(org2.description)
      expect(page).to have_content(sp.friendly_name)
      expect(page).to have_content(user.email)
      expect(page).to have_button('Create a new team')
    end

    scenario 'as logingov_readonly' do
      org1 = create(:team)
      org2 = create(:team)
      team = create(:team)
      sp = create(:service_provider, team:)
      user = create(:user, teams: [team])

      login_as(logingov_readonly)
      visit teams_all_path

      expect(page).to have_content(org1.name)
      expect(page).to have_content(org2.name)
      expect(page).to have_content(org1.uuid)
      expect(page).to have_content(org2.uuid)
      expect(page).to have_content(org1.agency.name)
      expect(page).to have_content(org2.agency.name)
      expect(page).to have_content(org1.description)
      expect(page).to have_content(org2.description)
      expect(page).to have_content(sp.friendly_name)
      expect(page).to have_content(user.email)
      expect(page).to_not have_button('Create a new team')
    end

    context 'in a prod_like_env' do
      before do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
      end

      context 'a user who is a login_admin' do
        let(:logingov_admin) { create(:user, :logingov_admin) }

        scenario 'should see create team button' do
          login_as(logingov_admin)
          visit teams_path

          expect(page).to have_button('Create a new team')
        end
      end

      context 'a user who is not a login_admin' do
        scenario 'should not see create team button' do
          user = create(:user)

          login_as(user)
          visit teams_path

          expect(page).to_not have_content('Create a new team')
          expect(page).to_not have_content('Create your first team')
        end
      end
    end
  end

  describe 'show' do
    scenario 'login.gov admin edits a team', :versioning do
      team = create(:team)
      user = create(:user, teams: [team])
      create(:service_provider, team:)

      login_as(logingov_admin)
      visit teams_all_path
      find("a[href='#{team_path(team)}']", text: team.name).click

      expect(page).to have_current_path(team_path(team))
      expect(page).to have_content(team.name)
      expect(page).to have_content(team.agency.name)
      expect(page).to have_content(user.email)

      find("a[href='#{team_users_path(team)}']", text: 'Manage users').click
      find("a[href='#{team_remove_confirm_path(team, user)}']").click
      click_on I18n.t('teams.users.remove.button')
      find('.usa-button', text: 'Back').click

      expect(page).to have_current_path(team_path(team))
      # Team UUID is displayed and has Copy button
      expect(page).to have_content(team.uuid)
      expect(page).to have_content('copy UUID to clipboard')
      newest_event_text = find('#versions>:first-child').text
      expect(newest_event_text).to include("user_id #{user.id}")
      expect(newest_event_text).to include("By: #{logingov_admin.email}")
      expect(newest_event_text).to include('Action: Remove')

      oldest_event_text = find('#versions>:last-child').text
      expect(oldest_event_text).to include('Action: Create')
      expect(oldest_event_text).to include("At: #{team.created_at}")
    end

    describe 'default roles' do
      scenario 'for the Login.gov Internal Team' do
        team = Team.internal_team
        user = create(:user)

        login_as(logingov_admin)
        visit teams_all_path
        find("a[href='#{team_path(team)}']", text: team.name).click

        expect(page).to have_current_path(team_path(team))
        expect(page).to have_content(team.name)
        expect(page).to have_content(team.agency.name)

        click_on 'Manage users'
        click_on 'Add user'
        fill_in 'Email', with: user.email
        click_on 'Add'

        expect(user.teams).to include(team)
        membership = user.team_memberships.find_by(group_id: team.id, user_id: user.id)
        expect(membership).to be_truthy
        expect(membership.role.name).to eq('logingov_readonly')
      end

      scenario 'for a team without a Partner Admin' do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(false)
        team = create(:team)
        user = create(:user)

        login_as(logingov_admin)
        visit team_path(team)
        click_on 'Manage users'
        click_on 'Add user'
        fill_in 'Email', with: user.email
        click_on 'Add'

        membership = user.team_memberships.find_by(group_id: team.id, user_id: user.id)
        expect(membership).to be_truthy
        expect(membership.role.name).to eq('partner_admin')
      end

      scenario 'for a team on Production' do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)

        partner_admin = create(:user, :partner_admin)
        team = partner_admin.teams.last
        user = create(:user)

        login_as(partner_admin)
        visit team_path(team)
        click_on 'Manage users'
        click_on 'Add user'
        fill_in 'Email', with: user.email
        click_on 'Add'

        membership = user.team_memberships.find_by(group_id: team.id, user_id: user.id)
        expect(membership).to be_truthy
        expect(membership.role.name).to eq('partner_readonly')
      end

      scenario 'for a team on Sandbox with a Partner Admin' do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(false)

        partner_admin = create(:user, :partner_admin)
        team = partner_admin.teams.last
        user = create(:user)

        login_as(partner_admin)
        visit team_path(team)
        click_on 'Manage users'
        click_on 'Add user'
        fill_in 'Email', with: user.email
        click_on 'Add'

        membership = user.team_memberships.find_by(group_id: team.id, user_id: user.id)
        expect(membership).to be_truthy
        expect(membership.role.name).to eq('partner_developer')
      end
    end

    scenario 'Login.gov Admin edits Internal Team user role' do
      team = Team.internal_team
      user = create(:user, :logingov_readonly)

      login_as(logingov_admin)
      visit team_path(team)
      click_on 'Manage users'
      find("a[href='#{team_users_path(team)}/#{user.id}/edit']", text: 'Edit').click

      [Role::LOGINGOV_ADMIN, Role::LOGINGOV_READONLY].each do |role|
        expect(page).to have_content(role.friendly_name)
        expect(page).to have_content(I18n.t("team_memberships.#{role.name}_description"))
      end
    end

    scenario 'login.gov readonly views team details' do
      team = create(:team)
      user = create(:user, teams: [team])
      create(:service_provider, team:)

      login_as(logingov_readonly)
      visit teams_all_path
      find("a[href='#{team_path(team)}']", text: team.name).click

      expect(page).to have_current_path(team_path(team))
      expect(page).to have_content(team.name)
      expect(page).to have_content(team.agency.name)
      expect(page).to have_content(user.email)
      expect(page).to have_content('Version History')

      # Team UUID is displayed and has Copy button
      expect(page).to have_content(team.uuid)
      expect(page).to have_content('copy UUID to clipboard')

      find("a[href='#{team_users_path(team)}']", text: 'Manage users').click
      find('.usa-button', text: 'Back').click

      expect(page).to have_current_path(team_path(team))
    end

    scenario 'readonly user attempts to edit a team' do
      team = create(:team)
      user = create(:team_membership, :partner_readonly, team:).user

      login_as(user)

      visit team_path(team)

      expect(page).to_not have_button('Edit')
      expect(page).to_not have_link('Manage users')

      visit edit_team_path(team)
      expect(page).to have_content('Unauthorized')

      visit teams_all_path
      expect(page).to_not have_button('Edit')
    end

    scenario 'regular user attempts to view a team' do
      user = create(:user)
      team = create(:team)
      create(:service_provider, team:)

      login_as(user)

      visit team_path(team)

      expect(page).to_not have_content(team.name)
      expect(page).to have_content('Unauthorized')
    end

    scenario 'regular user views own team' do
      user = create(:user, :team_member)
      team = user.teams.first

      login_as(user)

      visit team_path(team)

      expect(page).to have_content(team.name)
      expect(page).to_not have_content('Unauthorized')
      # Team UUID is not displayed
      expect(page).to_not have_content(team.uuid)
      expect(page).to_not have_content('copy UUID to clipboard')
    end
  end

  scenario 'Delete' do
    team = create(:team)
    login_as(logingov_admin)

    visit teams_all_path
    find("a[href='#{edit_team_path(team)}']").click
    click_on 'Delete'

    expect(page).to have_current_path(teams_all_path)
    expect(page).to have_content('Success')
    expect(page).to_not have_content(team.name)
  end

  scenario 'Delete when a team still has service providers' do
    team = create(:team)
    create(:service_provider, team:)

    login_as(logingov_admin)

    visit edit_team_path(team)
    click_on 'Delete'

    expect(page).to have_current_path(edit_team_path(team))
    expect(page).to have_content(I18n.t('notices.team_delete_failed'))
  end
end
