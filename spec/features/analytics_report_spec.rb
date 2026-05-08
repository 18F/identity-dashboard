require 'rails_helper'

describe 'reporting feature basics' do
  let(:logingov_admin) { create(:user, :logingov_admin) }
  let(:hardcoded_issuer_for_testing_mvp) do
    'urn:gov:gsa:openidconnect.profiles:sp:sso:dol_ebsa:lfdb'
  end
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
      login_as logingov_admin
    end

    it 'can view appropriate team and issuer options' do
      expect(test_sp).to be_valid
      visit analytics_path
      selection_texts = find_all('select').map(&:text)
      expect(selection_texts).to include(logingov_admin.teams.first.name)
      expect(selection_texts).to include(test_sp.friendly_name)
    end

    context 'testing charts in-browser', :js do
      before do
        expect(test_sp).to be_valid
        visit analytics_path
      end

      it 'tries to display each chart' do
        expect(page).to have_content('Service activity')
        expect(find_all('canvas').count).to eq(5)
        expect(page).to_not have_content('No data')
      end
    end

    it 'contains a link to download a CSV' do
      expect(test_sp).to be_valid
      visit analytics_path
      expect(page).to have_link('Download CSV', href: analytics_download_path)
    end

    it 'can download a CSV with report data' do
      expect(test_sp).to be_valid
      visit analytics_path
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
