require 'rails_helper'

describe 'reporting feature basics' do
  let(:logingov_admin) { create(:user, :logingov_admin) }
  let(:issuer_with_lots_of_test_data) do
    'urn:gov:gsa:openidconnect.profiles:sp:sso:dol_test'
  end
  let(:issuer_with_a_little_test_data) do
    'urn:gov:gsa:openidconnect.profiles:sp:sso:gsa:jonathan_demo'
  end
  let(:issuer_with_null_test_data) do
    '2025-12-10:Howard:test'
  end
  # make some teams and a service_provider
  let(:other_team) { create(:team) }
  let(:other_sp) { create(:service_provider, issuer: '6797', team: other_team) }
  let(:test_sp) do
    create(
      :service_provider,
      :ready_to_activate,
      issuer: issuer_with_lots_of_test_data,
      user: logingov_admin,
      team: logingov_admin.teams.first,
    )
  end
  let(:null_data_sp) do
    create(
      :service_provider,
      :ready_to_activate,
      issuer: issuer_with_null_test_data,
      user: logingov_admin,
      team: other_team,
    )
  end

  context 'without configs that have reports' do
    it 'shows an error message' do
      login_as logingov_admin
      visit analytics_path
      expect(page).to have_content(
        'You do not belong to any team that has a service provider configuration ' \
          'with reported data.',
      )
      sp_options = find_all('select#analytic_uuid > option')
      expect(sp_options.count).to be(1)
      expect(sp_options[0].text).to eq('- No Applications-')
    end
  end

  context 'as logingov_admin with configs that have reports' do
    before do
      other_sp
      test_sp
      (1..4).to_a.map { |_a| create(:team) }

      login_as logingov_admin
    end

    it 'can view appropriate team options' do
      visit analytics_path
      team_select = find('#analytic_team')
      team_opts = team_select.find_all('option')
      # options are each team plus All Teams
      expect(team_opts.count).to eq(Team.count + 1)
      expect(team_select.text).to include(logingov_admin.teams.first.name)
    end

    it 'does not show a report automatically' do
      visit analytics_path
      expect(page).to have_content('Choose from the dropdowns to see a report.')
      expect(page).to_not have_content('Date range')
      expect(page).to_not have_link('Export report as CSV')
    end

    it 'does not show a report error message before selecting a report' do
      visit analytics_path
      expect(page).to_not have_content(
        'We couldn\'t retrieve data matching your application and date.',
      )
    end

    context 'Filter', :js do
      let(:second_team) { create(:team) }
      let(:second_sp) do
        create(:service_provider,
                issuer: issuer_with_a_little_test_data,
                user: logingov_admin,
                team: second_team)
      end

      before do
        second_team and second_sp
        visit analytics_path
      end

      it 'shows the correct apps for a chosen team' do
        select second_team.name, from: 'Team'

        all_hidden_apps = page.find_all('#analytic_uuid .display-none')

        expect(page).to have_content(test_sp.friendly_name)
        expect(page).to have_content(second_sp.friendly_name)

        expect(all_hidden_apps.count).to eq(1)
        expect(all_hidden_apps.map(&:text)).to include(test_sp.friendly_name)
        expect(all_hidden_apps.map(&:text)).to_not include(second_sp.friendly_name)
      end

      it 'shows the correct apps when reselecting All teams' do
        select second_team.name, from: 'Team'
        select '- All Teams-', from: 'Team'

        all_hidden_apps = page.find_all('#analytic_uuid .display-none')

        expect(page).to have_content(test_sp.friendly_name)
        expect(page).to have_content(second_sp.friendly_name)

        expect(all_hidden_apps.count).to eq(0)
      end

      it 'shows the correct dates for a chosen application' do
        select second_sp.friendly_name, from: 'Application'

        all_hidden_dates = page.find_all('#analytic_date .display-none')

        expect(page).to have_content('2025-04-01')
        expect(page).to have_content('2025-08-01')
        expect(page).to have_content('2025-12-01')

        expect(all_hidden_dates.count).to eq(1)
        expect(all_hidden_dates.map(&:text)).to_not include('2025-04-01')
        expect(all_hidden_dates.map(&:text)).to_not include('2025-08-01')
        expect(all_hidden_dates.map(&:text)).to include('2025-12-01')
      end
    end

    it 'can update issuer and date options' do
      second_sp = create(:service_provider,
        issuer: issuer_with_a_little_test_data,
        user: logingov_admin,
        team: logingov_admin.teams.first)
      visit analytics_path

      select second_sp.friendly_name, from: 'Application'
      select test_sp.friendly_name, from: 'Application'
      select '2025-12-01', from: 'Date of report'
      click_on 'View report'
      expect(page).to have_current_path(analytics_path(
        team: test_sp.team.id,
        uuid: test_sp.uuid,
        date: '2025-12-01',
      ))
    end

    context 'when given invalid parameters' do
      it 'handles a bad team param' do
        visit analytics_path(
          team: 'A',
          uuid: test_sp.uuid,
          date: '2025-12-01',
        )
        expect(page).to have_content('- All Teams-')
      end

      it 'handles a bad config UUID param' do
        visit analytics_path(
          team: test_sp.team.id,
          uuid: 'INVALID-UUID',
          date: '2025-12-01',
        )
        expect(page).to have_content('The link for that report was not valid. ' \
          'You can select a different report from the options below.')
      end

      it 'handles a bad date param' do
        visit analytics_path(
          team: test_sp.team.id,
          uuid: test_sp.uuid,
          date: 'NOT-A-DATE',
        )
        expect(page).to have_content('Date is invalid')

        visit analytics_path
        expect(page).to_not have_content('The link for that report was not valid. ' \
          'You can select a different report from the options below.')
      end
    end

    context 'with a report loaded' do
      before do
        visit analytics_path
        select test_sp.team.name, from: 'Team'
        select test_sp.friendly_name, from: 'Application'
        select '2025-12-01', from: 'Date of report'
        click_on 'View report'
      end

      it 'displays an alert about billing details' do
        info_alert = find('.usa-alert--info')

        # rubocop:disable Layout/LineLength
        expect(info_alert.text).to eq(
          'The report is not representative of billed usage. For billing details refer to the monthly invoice.',
        )
        # rubocop:enable Layout/LineLength
      end

      context 'with charts rendering', :js do
        it 'tries to display each chart' do
          expect(page).to have_content('Date range')
          expect(find_all('canvas').count).to eq(2)
          expect(page).to_not have_content('No data')
        end

        it 'displays additional data' do
          expect(page.text).to match(/successful authentications\s*1,282/i)
        end
      end

      it 'can download a CSV with report data' do
        expect(page).to have_link('Export report as CSV', href: analytics_path(
          team: test_sp.team.id,
          uuid: test_sp.uuid,
          date: '2025-12-01',
          format: 'csv',
        ))
        click_on 'Export report as CSV'

        expect(response_headers['content-type']).to start_with('text/csv')
        csv_response = CSV.parse(body)
        expect(csv_response.length).to eq(39)
        expect(csv_response[0]).to eq(['', 'Quarterly', 'Monthly', 'Weekly'])
        expect(csv_response[1]).to eq(['Start Date', '', '2025-12-01', ''])
        expect(csv_response[2]).to eq(['Newly Created Accounts', '', '1173', ''])
        expect(csv_response[6]).to eq(['Inauthentic Doc.', '', '475', ''])
        expect(csv_response[30]).to eq(['Doc. Auth. Processing Issue', '', '2', ''])
        expect(csv_response[38]).to eq(['Personal Key', '', '0', ''])
      end
    end
  end

  context 'as a partner admin' do
    let(:partner_admin) { create(:team_membership, :partner_admin).user }
    let(:issuer) { issuer_with_lots_of_test_data }
    let!(:partner_sp) do
      create(
        :service_provider,
        :ready_to_activate,
        user: partner_admin,
        team: partner_admin.teams.first,
        issuer:,
      )
    end

    before do
      login_as partner_admin
      visit analytics_path
    end

    it 'can display charts', :js do
      select partner_sp.friendly_name, from: 'Application'
      select '2025-12-01', from: 'Date of report'
      click_on 'View report'
      expect(page).to have_current_path(analytics_path(
        team: partner_sp.team.id,
        uuid: partner_sp.uuid,
        date: '2025-12-01',
      ))
      expect(find_all('canvas').count).to eq(2)
    end

    context 'with mostly missing data' do
      # This issuer has mostly null data, but a few zeroes
      let(:issuer) { '2025-12-10:Howard:test' }

      it 'will display charts and unavailable messages', :js do
        select partner_sp.friendly_name, from: 'Application'
        select '2025-08-01', from: 'Date of report'
        click_on 'View report'
        expect(find_all('canvas').count).to eq(1)
        expect(page.text).to match(/BLOCKED USERS\s*Data is currently not available/)
        expect(page.text).to match(/requiring verification\sData is currently not available/)
        expect(page).to_not have_button('Export report as CSV')
      end
    end
  end
end
