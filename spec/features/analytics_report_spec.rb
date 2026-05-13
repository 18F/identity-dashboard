require 'rails_helper'

describe 'reporting feature basics' do
  let(:logingov_admin) { create(:user, :logingov_admin) }
  let(:hardcoded_issuer_for_testing_mvp) do
    'urn:gov:gsa:openidconnect.profiles:sp:sso:dol_ebsa:lfdb'
  end
  # make some teams and a service_provider
  let(:other_team) { create(:team) }
  let(:other_sp) { create(:service_provider, issuer: '6797', team: other_team) }
  let(:test_sp) do
    create(
      :service_provider,
      issuer: hardcoded_issuer_for_testing_mvp,
      user: logingov_admin,
      team: logingov_admin.teams.first,
    )
  end

  context 'as logingov_admin' do
    before do
      # this order matters until we can specify an SP on /reports
      other_sp
      test_sp
      teams = (1..4).to_a.map { |a| create(:team) }

      login_as logingov_admin
      visit analytics_path
    end

    it 'can view appropriate team options' do
      team_select = find('#analytic_team')
      team_opts = team_select.find_all('option')

      expect(team_opts.count).to eq(Team.count)
      expect(team_select.text).to include(logingov_admin.teams.first.name)
    end

    it 'can view appropriate service provider options' do
      team_select = find('#analytic_team')
      team_opts = team_select.find_all('option')
      sp_select = find('#analytic_friendly_name')
      sp_opts = sp_select.find_all('option')

      expect(sp_opts.count).to eq(2)
      expect(sp_select.text).to include(test_sp.friendly_name)
      expect(sp_select.text).to include(other_sp.friendly_name)
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
        expect(page.text).to match(/applications\s*8/i)
      end
    end

    it 'contains a link to download a CSV' do
      expect(page).to have_link('Download CSV', href: analytics_download_path)
    end

    it 'can download a CSV with report data' do
      select(test_sp.team.name, from: 'Team')
      select(test_sp.friendly_name, from: 'Service Provider')
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
