require 'rails_helper'

describe Report::Base do
  describe 'integrated with a report' do
    let(:analytic) do
      analytic = Analytic.new
      analytic.config = build(
        :service_provider,
        :ready_to_activate,
        issuer: 'urn:gov:gsa:openidconnect.profiles:sp:sso:dol_test',
      )
      analytic.date = '2025-12-01'
      analytic
    end

    let(:reports) { Reports.new(analytic) }

    subject { described_class.new(reports) }

    it 'can return the data #as_array_with_i18n_labels' do
      expected_data = [
        ["Number of Users Who Accessed Your Services", 190],
        ["Number of Users blocked for Attempted Fraud", 16], ["Newly Created Accounts", 68],
        ["Existing Accounts", 120], ["Identity Verified Users", 20], ["Newly Proofed Users", 16],
        ["Preverified Users", 4], ["Authentications", 898], ["Account Creation", 5],
        ["Authentic Driver's License", 1], ["Facial Mismatch", 1],
        ["Invalid Attributes (DL, DOS)", 1], ["Identity Not Found (SSN / DOB / Deceased)", 1],
        ["Fraud Alert Detected", 0], ["Suspicious Phone", 1], ["Lacking Phone Ownership", 0],
        ["Wrong Phone Type", 0], ["Failed In-Person and Blocked", 0],
        ["Device and Behavior Fraud Signals", 0], ["Adjudicated as Legitimate", 2],
        ["Account Creation Success", 66], ["Authentication Success", 672],
        ["Device Type Desktop", 595], ["Device Type Mobile", 77], ["Face / Touch", 8],
        ["Authenticator App", 61], ["PIV / CAC", 15], ["SMS", 507], ["Voice", 12],
        ["Backup Code", 21], ["Security Key", 0], ["Personal Key", 0], ["Proofing Success", 17],
        ["Preverified", 0], ["Remote Unattended", 17], ["In-Person Proofed", 0],
        ["Pass via Letter", 0], ["Blocked at Document Upload UX", 0], ["Selfie UX Issue", 0],
        ["Identity Resolution Attribute Mismatch", 0], ["Phone Number Record Check Failure", 0],
        ["Temporary Technical Issue", 0]
      ]
      expect(subject.as_array_with_i18n_labels).to eq(expected_data)
    end

    it '#as_array_with_i18n_labels skips invalid keys' do
      expected_count = rand(1..10000)
      storage_mock = instance_double(AnalyticsReportStorage)
      allow(AnalyticsReportStorage).to receive(:new)
        .with(analytic.config.issuer, analytic.date)
        .and_return(storage_mock)
      allow(storage_mock).to receive(:fetch).and_return(
        { 'data' => {
          'count_blocked_attempted_fraud' => expected_count,
          'invalid_key' => rand(100..10_000),
          'count_other_invalid_key' => rand(10..1000),
        } },
      )
      expect(subject.as_array_with_i18n_labels).to eq(
        [[I18n.t('reports.count_blocked_attempted_fraud'), expected_count]],
      )
    end

    it 'raises a NotImplementedError for #chart' do
      expect { subject.chart }.to raise_error(NotImplementedError)
    end

    it 'raises a NotImplementedError for #total' do
      expect { subject.total }.to raise_error(NotImplementedError)
    end
  end
end
