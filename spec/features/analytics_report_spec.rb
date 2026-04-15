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

  it 'logingov admin can get the page', :js do
    expect(test_sp).to be_valid
    login_as logingov_admin
    visit analytics_path
    selection_texts = find_all('select').map(&:text)
    expect(selection_texts).to include(logingov_admin.teams.first.name)
    expect(selection_texts).to include(test_sp.friendly_name)
  end
end
