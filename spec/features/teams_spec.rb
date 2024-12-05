require 'rails_helper'

feature 'User teams CRUD' do
  [true, false].each do |with_rbac|
    describe(with_rbac ? 'with RBAC' : 'without RBAC') do
      before do
        if with_rbac
          allow(IdentityConfig.store).
            to receive(:access_controls_enabled).
            and_return(true)
        else
          allow(IdentityConfig.store).
            to receive(:access_controls_enabled).
            and_return(false)
        end
      end

      scenario 'Create' do
        admin = create(:admin)
        create(:agency, name: 'GSA')

        login_as(admin)
        visit new_team_path

        fill_in 'Description', with: 'department name'
        fill_in 'Name', with: 'team name'
        select('GSA', from: 'Agency')

        click_on 'Create'
        expect(current_path).to eq(team_users_path(Team.last))
        expect(page).to have_content('Success')
        expect(page).to have_content('team name')
      end

      context 'User already in a team' do
        scenario 'User does show up in user team that they are assigned to' do
          admin = create(:admin)
          user = create(:user)
          team = create(:team, users: [user])

          login_as(admin)
          visit edit_team_path(team)

          expect(page).to have_content(user.email)
        end

        scenario 'User can be added to another team' do
          admin = create(:admin)
          user = create(:user)
          team1 = create(:team, users: [user])
          team2 = create(:team)

          login_as(admin)
          visit edit_team_path(team2)
          click_on 'Manage users'
          click_on 'Add user'
          fill_in 'Email', with: user.email
          click_on 'Add'
          expect(user.teams).to include(team1, team2)
        end
      end

      scenario 'Update' do
        admin = create(:admin)
        org = create(:team)
        create(:agency, name: 'USDS')
        login_as(admin)

        visit teams_all_path
        find("a[href='#{edit_team_path(org)}']").click
        expect(current_path).to eq(edit_team_path(org))

        fill_in 'Name', with: 'updated team'
        fill_in 'Description', with: 'updated department'
        select('USDS', from: 'Agency')
        click_on 'Update'

        expect(current_path).to eq(team_path(org.id))
        expect(page).to have_content('Success')
        expect(page).to have_content('USDS')
        expect(page).to have_content('updated department')
        expect(page).to have_content('updated team')
      end

      scenario 'Index' do
        admin = create(:admin)
        org1 = create(:team)
        org2 = create(:team)
        team = create(:team)
        sp = create(:service_provider, team:)

        login_as(admin)
        visit teams_all_path

        expect(page).to have_content(org1.name)
        expect(page).to have_content(org2.name)
        expect(page).to have_content(org1.agency.name)
        expect(page).to have_content(org2.agency.name)
        expect(page).to have_content(org1.description)
        expect(page).to have_content(org2.description)
        expect(page).to have_content(sp.friendly_name)
      end

      describe 'show' do
        scenario 'admin edits a team', versioning: true do
          admin = create(:admin)
          team = create(:team)
          user = create(:user, teams: [team])
          create(:service_provider, team:)

          login_as(admin)
          visit teams_all_path
          find("a[href='#{team_path(team)}']", text: team.name).click

          expect(current_path).to eq(team_path(team))
          expect(page).to have_content(team.name)
          expect(page).to have_content(team.agency.name)
          expect(page).to have_content(user.email)

          find("a[href='#{team_users_path(team)}']", text: 'Manage users').click
          find("a[href='#{team_remove_confirm_path(team, user)}']").click
          click_on I18n.t('teams.users.remove.button')
          find('.usa-button', text: 'Back').click

          expect(current_path).to eq(team_path(team))
          newest_event_text = find('#versions>:first-child').text
          expect(newest_event_text).to include("user_id #{user.id}")
          expect(newest_event_text).to include("By: #{admin.email}")
          expect(newest_event_text).to include('Action: Remove')

          oldest_event_text = find('#versions>:last-child').text
          expect(oldest_event_text).to include('Action: Create')
          expect(oldest_event_text).to include("At: #{team.created_at}")
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
      end

      scenario 'Delete' do
        admin = create(:admin)
        team = create(:team)
        login_as(admin)

        visit teams_all_path
        find("a[href='#{edit_team_path(team)}']").click
        click_on 'Delete'

        expect(current_path).to eq(teams_path)
        expect(page).to have_content('Success')
        expect(page).to_not have_content(team.name)
      end

      scenario 'Delete when a team still has service providers' do
        admin = create(:admin)
        team = create(:team)
        create(:service_provider, team:)

        login_as(admin)

        visit edit_team_path(team)
        click_on 'Delete'

        expect(current_path).to eq(edit_team_path(team))
        expect(page).to have_content(I18n.t('notices.team_delete_failed'))
      end
    end
  end
end
