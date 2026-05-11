require 'rails_helper'

RSpec.describe AnalyticsReportStorage::ReportFile do
  it 'can infer an issuer' do
    fixture_key = 'urn:gov:gsa:openidconnect.profiles:sp:sso:dol_ebsa:lfdb/monthly/2025-12-01.json'
    subject = described_class.new(key: fixture_key)
    expect(subject.sp_identifier).to eq('urn:gov:gsa:openidconnect.profiles:sp:sso:dol_ebsa:lfdb')

    subject_with_id = described_class.new(key: '255/monthly/2025-04-01.json')
    expect(subject_with_id.sp_identifier).to eq('255')
  end
end
