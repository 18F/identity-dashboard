require 'rails_helper'

describe 'reporting feature basics' do
  let(:logingov_admin) { create(:user, :logingov_admin) }
  let(:issuer_with_lots_of_test_data) do
    'urn:gov:gsa:openidconnect.profiles:sp:sso:dol_test'
  end
  let(:issuer_with_a_little_test_data) do
    'urn:gov:gsa:openidconnect.profiles:sp:sso:gsa:jonathan_demo'
  end
  # make some teams and a service_provider
  let(:other_team) { create(:team) }
  let(:other_sp) { create(:service_provider, issuer: '6797', team: other_team) }
  let(:test_sp) do
    create(
      :service_provider,
      issuer: issuer_with_lots_of_test_data,
      user: logingov_admin,
      team: logingov_admin.teams.first,
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
      sp_options = find_all('select#analytic_friendly_name > option')
      expect(sp_options.count).to be(1)
      expect(sp_options[0].text).to eq('- All SPs-')
    end
  end

  context 'as logingov_admin with configs that have reports' do
    before do
      # this order matters until we can specify an SP on /reports
      other_sp
      test_sp
      (1..4).to_a.map { |_a| create(:team) }

      login_as logingov_admin
      visit analytics_path
    end

    it 'can view appropriate team options' do
      team_select = find('#analytic_team')
      team_opts = team_select.find_all('option')

      expect(team_opts.count).to eq(Team.count)
      expect(team_select.text).to include(logingov_admin.teams.first.name)
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
    end

    it 'displays an alert about billing details' do
      info_alert = find('.usa-alert--info')

      # rubocop:disable Layout/LineLength
      expect(info_alert.text).to eq(
        'The report is not representative of billed usage. For billing details refer to the monthly invoice.',
      )
      # rubocop:enable Layout/LineLength
    end

    context 'testing charts in-browser', :js do
      before do
        expect(test_sp).to be_valid
        visit analytics_path
      end

      it 'tries to display each chart' do
        expect(page).to have_content('Service activity')
        expect(find_all('canvas').count).to eq(2)
        expect(page).to_not have_content('No data')
      end

      it 'displays additional data' do
        expect(page.text).to match(/successful authentications\s*1,282/i)
      end
    end

    it 'contains a link to download a CSV' do
      expect(page).to have_link('Export report to CSV', href: analytics_download_path)
    end

    it 'can download a CSV with report data' do
      select(test_sp.team.name, from: 'Team')
      select(test_sp.friendly_name, from: 'Application')
      download_button = find '#download-csv'
      download_button.click

      expect(response_headers['content-type']).to start_with('text/csv')
      csv_response = CSV.parse(body)
      expect(csv_response.length).to eq(39)
      expect(csv_response[0]).to eq(['', 'Quarterly', 'Monthly', 'Weekly'])
      expect(csv_response[1]).to eq(['Start Date', '', '2025-12-01 00:00:00', ''])
      expect(csv_response[2]).to eq(['Newly Created Accounts', '', '1173', ''])
      expect(csv_response[6]).to eq(['Inauthentic Doc.', '', '475', ''])
      expect(csv_response[30]).to eq(['Doc. Auth. Processing Issue', '', '2', ''])
      expect(csv_response[38]).to eq(['Personal Key', '', '0', ''])
    end
  end
end
