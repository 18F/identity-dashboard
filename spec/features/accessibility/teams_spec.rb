require 'rails_helper'
require 'axe-rspec'

feature 'Team pages', :js do
  let(:user) { create(:user, :with_teams) }
  let(:team) { user.teams.first }

  before  { login_as(user) }

  context 'as a login.gov admin' do
    let(:user) { create(:logingov_admin) }

    context 'index page' do
      scenario 'is accessible' do
        visit teams_path
        expect_page_to_have_no_accessibility_violations(page)
      end
    end

    context 'all teams page' do
      scenario 'is accessible' do
        visit teams_all_path
        expect_page_to_have_no_accessibility_violations(page)
      end
    end

    context 'new team page' do
      scenario 'is accessible' do
        visit new_team_path
        expect_page_to_have_no_accessibility_violations(page)
      end
    end
  end

  context 'as a user' do
    let(:user_team_membership) { create(:user_team) }
    let(:user) { user_team_membership.user }
    let(:team) { user_team_membership.team }

    context 'editing an existing team' do
      scenario 'view is accessible' do
        visit edit_team_path(team)
        expect_page_to_have_no_accessibility_violations(page)
      end
    end

    context 'creating a new team' do
      context 'user has a .gov email address (without RBAC)' do
        before do
          allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)

          create(:agency, name: 'GSA')

          visit new_team_path
          fill_in 'Name', with: 'team name'
          select('GSA', from: 'Agency')
          fill_in 'Description', with: 'department name'
          click_on 'Create'
        end

        describe 'new team view' do
          scenario 'is accessible' do
            expect_page_to_have_no_accessibility_violations(page)
          end
        end

        context 'adding a user' do
          before do
            click_on 'Add user'
          end

          describe 'add new user to team view' do
            scenario 'is accessible' do
              expect_page_to_have_no_accessibility_violations(page)
            end
          end

          context 'add email' do
            let(:email) { 'user@example.com' }

            before do
              fill_in 'Email', with: email
              click_on 'Add'
            end

            context 'bad email' do
              let(:email) { 'blah ' }

              scenario 'is accessible' do
                expect_page_to_have_no_accessibility_violations(page)
              end
            end

            context 'valid email is added' do
              scenario 'is accessible' do
                expect_page_to_have_no_accessibility_violations(page)
              end
            end

            context 'returning to the users view with a user', :versioning do
              before do
                click_on 'Back'
              end

              scenario 'is accessible' do
                expect_page_to_have_no_accessibility_violations(page)
              end
            end
          end
        end
      end

      context 'user has a .com email address (without RBAC)' do
        before do
          allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
          user.update(email: 'user@example.com')

          visit new_team_path
        end

        describe 'unauthorized new team view' do
          scenario 'is accessible' do
            expect_page_to_have_no_accessibility_violations(page)
          end
        end
      end

      context 'as a Partner Admin' do
        let(:user_team_membership) { create(:user_team, :partner_admin) }

        before do
          allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(true)
        end

        it 'is accessible when creating a new team' do
          create(:agency, name: 'GSA')

          visit new_team_path
          expect_page_to_have_no_accessibility_violations(page)
          fill_in 'Name', with: 'team name'
          select('GSA', from: 'Agency')
          fill_in 'Description', with: 'department name'
          click_on 'Create'
          expect_page_to_have_no_accessibility_violations(page)
        end

        describe 'adding users workflow' do
          describe 'add new user to team view' do
            it 'is accessible' do
              visit team_path(user_team_membership.team)
              click_on 'Manage users'
              expect_page_to_have_no_accessibility_violations(page)

              click_on 'Add user'

              # Asserting this so we can rely on `new_team_user_path` for subsequent scenarios
              expect(page).to have_current_path(new_team_user_path(user_team_membership.team))

              expect_page_to_have_no_accessibility_violations(page)
            end
          end

          describe 'adding a user' do
            before do
              visit new_team_user_path(user_team_membership.team)
              fill_in 'Email', with: email
              click_on 'Add'
            end

            context 'with a good email' do
              let(:email) { 'user@example.com' }

              it 'is accessible' do
                expect_page_to_have_no_accessibility_violations(page)
              end

              describe 'returning after adding the user', :versioning do
                before do
                  click_on 'Back'
                end

                it 'is accessible' do
                  expect_page_to_have_no_accessibility_violations(page)
                end
              end
            end

            context 'with a bad email' do
              let(:email) { 'blah ' }

              scenario 'is accessible' do
                expect_page_to_have_no_accessibility_violations(page)
              end
            end
          end
        end
      end

      context 'as a Partner Readonly user' do
        let(:user_team_membership) { create(:user_team, :partner_readonly) }

        context 'the team page' do
          before do
            visit team_path(user_team_membership.team)
          end

          it { expect_page_to_have_no_accessibility_violations(page) }
        end

        context 'adding a user' do
          before do
            visit new_team_user_path(user_team_membership.team)
          end

          it 'is accessible even when unauthorized' do
            expect(page).to have_text('Unauthorized')
            expect_page_to_have_no_accessibility_violations(page)
          end
        end
      end
    end
  end
end
