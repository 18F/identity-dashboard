require 'rails_helper'
require 'axe-rspec'

feature 'Team pages', :js do
  let(:user) { create(:user, :with_teams) }
  let(:team) { user.teams.first }

  before  { login_as(user) }

  context 'as an admin' do
    let(:user) { create(:admin) }

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
    context 'editing an existing team' do
      scenario 'view is accessible' do
        visit edit_team_path(team)
        expect_page_to_have_no_accessibility_violations(page)
      end
    end

    context 'creating a new team' do
      context 'user has a .gov email address' do
        before do
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
              let(:email) { 'blah '}
              scenario 'is accessible' do
                expect_page_to_have_no_accessibility_violations(page)
              end
            end

            context 'valid email is added' do
              scenario 'is accessible' do
                expect_page_to_have_no_accessibility_violations(page)
              end
            end

            context 'returning to the users view with a user' do
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

      context 'user has a .com email address' do
        before do
          user.update(email: 'user@example.com')

          visit new_team_path
        end

        describe 'unauthorized new team view' do
          scenario 'is accessible' do
            expect_page_to_have_no_accessibility_violations(page)
          end
        end
      end
    end
  end
end
