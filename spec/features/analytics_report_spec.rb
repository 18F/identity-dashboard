require 'rails_helper'

describe 'reporting feature basics' do
  let(:logingov_admin) { create(:user, :logingov_admin) }
  let(:logingov_readonly) { create(:user, :logingov_readonly) }
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
      expect(sp_options[0].text).to eq(t('reports.inputs.prompts.no_app'))
    end
  end

  ['admin', 'readonly'].each do |role_name|
    context "as logingov_#{role_name} with configs that have reports" do
      let(:role) { role_name == 'admin' ? logingov_admin : logingov_readonly }

      before do
        other_sp
        test_sp
        (1..4).to_a.map { |_a| create(:team) }

        login_as role
      end

      it 'can view appropriate team options' do
        # Issuer for `null_data_sp` is in the issuers_service_provider_id.json
        # Adding it here so we have a more thorough test.
        null_data_sp

        visit analytics_path
        team_select = find('#analytic_team')
        team_opts = team_select.find_all('option')
        # Each team with a config referenced in the issuers_service_provider_id.json,
        # plus "All Teams"
        expect(team_opts.count).to eq(2 + 1)
        expect(team_select.text).to include(logingov_admin.teams.first.name)
      end

      it 'does not show a report automatically' do
        visit analytics_path
        expect(page).to have_content('Choose from the dropdowns to see a report.')
        expect(page).to_not have_content('Date range')
        expect(page).to_not have_content('Issuer')
        expect(page).to_not have_link('Export report as CSV')
      end

      it 'does not show a report error message before selecting a report' do
        visit analytics_path
        expect(page).to_not have_content(
          'We couldn\'t retrieve data matching your application and date.',
        )
      end

      context 'Filter', :js do
        let!(:second_team) { create(:team) }
        let!(:second_sp) do
          create(:service_provider,
                  :ready_to_activate,
                  issuer: issuer_with_a_little_test_data,
                  user: logingov_admin,
                  team: second_team)
        end

        before do
          visit analytics_path
        end

        it 'shows the correct apps for a chosen team' do
          select second_team.name, from: t('reports.inputs.labels.team')

          expect(page).to_not have_content(test_sp.friendly_name)
          expect(page).to have_content(second_sp.friendly_name)
        end

        it 'shows the correct apps when reselecting All teams' do
          select second_team.name, from: t('reports.inputs.labels.team')
          select t('reports.inputs.prompts.team'), from: t('reports.inputs.labels.team')

          expect(page).to have_content(test_sp.friendly_name)
          expect(page).to have_content(second_sp.friendly_name)
        end

        context 'with dates computed from created_at' do
          before do
            allow(IdentityConfig.store).to receive(:aws_reports_bucket).and_return('bucket')
            allow(IdentityConfig.store).to receive(:aws_reports_path).and_return('prefix')
            travel_to(Date.new(2026, 1, 15))
            visit analytics_path
          end

          around(&:run)

          let(:test_sp) do
            create(
              :service_provider,
              :ready_to_activate,
              issuer: issuer_with_lots_of_test_data,
              user: logingov_admin,
              team: logingov_admin.teams.first,
              created_at: Date.new(2025, 8, 1),
            )
          end
          let(:second_sp) do
            create(:service_provider,
                    :ready_to_activate,
                    issuer: issuer_with_a_little_test_data,
                    user: logingov_admin,
                    team: second_team,
                    created_at: Date.new(2025, 10, 15))
          end

          it 'shows the correct dates for a chosen application' do
            select second_sp.friendly_name, from: t('reports.inputs.labels.app')

            expect(page).to_not have_content('2025-10-01')
            expect(page).to have_content('2025-11-01')
            expect(page).to have_content('2025-12-01')
          end
        end
      end

      it 'can update issuer and date options' do
        second_sp = create(:service_provider,
          issuer: issuer_with_a_little_test_data,
          user: logingov_admin,
          team: logingov_admin.teams.first)
        visit analytics_path

        select second_sp.friendly_name, from: t('reports.inputs.labels.app')
        select test_sp.friendly_name, from: t('reports.inputs.labels.app')
        select '2025-12-01', from: t('reports.inputs.labels.date')
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
          expect(page).to have_content(t('reports.inputs.prompts.team'))
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
          select test_sp.team.name, from: t('reports.inputs.labels.team')
          select test_sp.friendly_name, from: t('reports.inputs.labels.app')
          select '2025-12-01', from: t('reports.inputs.labels.date')
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
            expect(page).to have_content('Issuer')
            expect(page).to have_content(issuer_with_lots_of_test_data)
            expect(page).to have_content('Date range')
            expect(page).to have_content('2025-12-01')
            expect(find_all('svg').count).to eq(2)
            expect(page).to_not have_content('No data')
            expect(page).to_not have_content('not available')
          end

          it 'displays additional data' do
            expect(page).to have_content(/successful authentications\s*1,029/i)
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
          expect(csv_response.length).to eq(45)
          expect(csv_response[0]).to eq(['', 'Description', 'Quarterly', 'Monthly', 'Weekly'])
          expect(csv_response[1]).to eq(
            ['Start Date', 'First day of the reporting month', '', '2025-12-01', ''],
          )
        end

        it 'allows switching between tabs', :js do
          expect(page).to have_content 'Fraud Prevention'
          click_on 'Fraud Prevention'
          expect(page).to_not have_content 'SUCCESSFUL AUTHENTICATIONS'
          expect(page).to have_content 'Fraudsters Blocked'
          click_on 'Usage'
          expect(page).to have_content 'SUCCESSFUL AUTHENTICATIONS'
          expect(page).to_not have_content 'Fraudsters Blocked'
        end

        it 'can show Identity Verification tab data', :js do
          click_on 'Identity Verification'

          charts = find_all('svg')
          proofing_success = charts.first
          access_path = charts[1]
          channels = charts[2]
          friction = charts[3]
          proofing_title = proofing_success.find_all('text')[0].text
          access_title = access_path.find_all('text')[0].text
          channels_title = channels.find_all('text')[0].text
          friction_title = friction.find_all('text')[0].text

          expect(proofing_title).to eq('Proofing Success Rate')
          expect(access_title).to eq('Path to Access Rate')
          expect(channels_title).to eq('Identity Verification Channels')
          expect(friction_title).to eq('Points of User Friction')

          channels_labels = channels.find_all('.highcharts-data-label')
          proofing_success_labels = proofing_success.find_all('.highcharts-data-label')
          friction_labels = friction.find_all('.highcharts-xaxis-labels > text')

          # Labels on stacked bar charts are different:
          # * It has `.highcharts-data-label`s but they're hidden by default
          # * Selecting hidden SVG elements often completely breaks
          # * In theory we could hover over each bar to show the hidden ones
          # * Selecting the correct bar and hovering over it in Capybara is messy
          # * It's easiest to look for the legend label text instead
          access_path_labels = access_path.find_all('.highcharts-legend-item')

          expect(proofing_success_labels.map(&:text)).to eq(['Pass', 'Not Pass'])
          expect(access_path_labels[0].text).to eq('Path Forward')
          expect(access_path_labels[1].text).to eq('Dead End')
          expect(channels_labels.map(&:text)).to eq([
                                                      'Remote Unattended',
                                                      'Preverified',
                                                      'In-Person Proofing',
                                                      'Physical Letter',
                                                    ])
          friction_text = friction_labels.map(&:text)

          expect(friction_text[0]).to eq('Document Upload UX')
          expect(friction_text[1]).to eq('Temporary Technical Issue')
          expect(friction_text[2]).to eq('Selfie UX Issue')
          # These sometime have a zero-width space. It varies based on the chromdriver window size
          expect(friction_text[3]).to match(/Identity\sResolution\sAttribute\s?Mismatch/)
          expect(friction_text[4]).to match(/Phone Number Record Check\s?Failure/)
        end

        it 'can show Authentication tab data', :js do
          click_on 'Authentication'
          expect(page).to have_content('Percentage of successful new accounts')
          expect(page).to have_text(/account creation success rate\s*100.0%/i)
          success_summary = find_all('div.data-summary')[3]
          expect(success_summary).to have_text(/authentication success rate\s*96.4%/i)
          expect(success_summary).to have_text(
            'out of total attempts excluding where users were already signed in',
          )

          charts = find_all('svg')
          device_chart = charts.first
          mfa_chart = charts[1]
          device_title = device_chart.find_all('text')[0].text
          mfa_title = mfa_chart.find_all('text')[0].text

          expect(device_title).to eq('Device Type')
          expect(mfa_title).to eq('Multi-Factor Authentication (MFA) Type')

          device_labels = device_chart.find_all('.highcharts-data-label')
          mfa_y_labels = mfa_chart.find('.highcharts-xaxis-labels').find_all('text')
          expect(device_labels.map(&:text)).to eq(['Desktop', 'Mobile'])
          expect(mfa_y_labels.map(&:text)).to eq([
                                                   'Face / Touch',
                                                   'Personal Key',
                                                   'Authenticator App',
                                                   'PIV / CAC',
                                                   'SMS',
                                                   'Voice',
                                                   'Backup Code',
                                                   'Security Key',
                                                 ])
        end
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

    it 'defaults to showing prompt for App', :js do
      app_select = page.find('#analytic_uuid')
      app_option0 = app_select.find_all('option').first

      expect(app_select.value).to eq('')
      expect(app_option0.value).to eq('')
      expect(app_option0.text).to eq(t('reports.inputs.prompts.app'))
    end

    it 'defaults to showing prompt for Date', :js do
      date_select = page.find('#analytic_date')
      date_option0 = date_select.find_all('option').first

      expect(date_select.value).to eq('')
      expect(date_option0.value).to eq('')
      expect(date_option0.text).to eq(t('reports.inputs.prompts.date'))
    end

    it 'uses the most recent date when none is selected', :js do
      select partner_sp.friendly_name, from: t('reports.inputs.labels.app')
      click_on 'View report'
      expect(page).to have_current_path(analytics_path(
        team: partner_sp.team.id,
        uuid: partner_sp.uuid,
        date: Date.current.beginning_of_month.prev_month.strftime('%F'),
      ))
    end

    it 'can display charts', :js do
      select partner_sp.friendly_name, from: t('reports.inputs.labels.app')
      select '2025-12-01', from: t('reports.inputs.labels.date')
      click_on 'View report'
      expect(page).to have_current_path(analytics_path(
        team: partner_sp.team.id,
        uuid: partner_sp.uuid,
        date: '2025-12-01',
      ))
      expect(find_all('svg').count).to eq(2)
    end

    it 'allows switching between tabs', :js do
      select partner_sp.friendly_name, from: t('reports.inputs.labels.app')
      select '2025-12-01', from: t('reports.inputs.labels.date')
      click_on 'View report'
      expect(page).to have_content 'Fraud Prevention'
      click_on 'Fraud Prevention'
      expect(page).to_not have_content 'SUCCESSFUL AUTHENTICATIONS'
      expect(page).to have_content 'Fraudsters Blocked'
      click_on 'Usage'
      expect(page).to have_content 'SUCCESSFUL AUTHENTICATIONS'
      expect(page).to_not have_content 'Fraudsters Blocked'
    end

    it 'can show Authentication tab data', :js do
      select partner_sp.friendly_name, from: t('reports.inputs.labels.app')
      select '2025-12-01', from: t('reports.inputs.labels.date')
      click_on 'View report'
      click_on 'Authentication'

      expect(find_all('svg').count).to eq(2)
    end

    it 'can show Identity Verification tab data', :js do
      select partner_sp.friendly_name, from: t('reports.inputs.labels.app')
      select '2025-12-01', from: t('reports.inputs.labels.date')
      click_on 'View report'
      click_on 'Identity Verification'

      expect(find_all('svg').count).to eq(4)
    end

    context 'with mostly missing data' do
      # This issuer has mostly null data, but a few zeroes
      let(:issuer) { '2025-12-10:Howard:test' }

      it 'will display charts and unavailable messages', :js do
        select partner_sp.friendly_name, from: t('reports.inputs.labels.app')
        select '2025-10-01', from: t('reports.inputs.labels.date')
        click_on 'View report'

        expect(find_all('svg').count).to eq(1)
        expect(page.text).to match(/BLOCKED USERS\s*Data is currently not available/)
        expect(page.text).to match(/requiring verification\s*Data is currently not available/)
        expect(page).to_not have_button('Export report as CSV')
      end
    end

    it 'does not display charts when the user does not have permission', :js do
      partner_readonly = create(:user)
      create(:team_membership, :partner_readonly, user: partner_readonly,
                                                  team: partner_admin.teams.first)
      create(:team_membership, :partner_admin, user: partner_readonly, team: other_team)

      login_as partner_readonly
      visit analytics_path(
        team: partner_sp.team.id,
        uuid: partner_sp.uuid,
        date: '2025-08-01',
      )

      expect(find_all('svg').count).to eq(0)
      expect(page.text).to match(I18n.t('reports.errors.generic'))
    end

    it 'does not include teams that have no eligible data' do
      create(:team_membership, :partner_admin, user: partner_admin, team: other_team)
      inelegible_config = create(:service_provider, :ready_to_activate, team: other_team)
      expect(other_team.service_providers.count).to be(1)

      visit analytics_path

      team_options = find_all('#analytic_team > option')
      expect(team_options.map(&:text)).to include(partner_sp.team.name)
      expect(team_options.map(&:text)).to_not include(inelegible_config.team.name)
    end
  end
end
