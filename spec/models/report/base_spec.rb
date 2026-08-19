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
        ['Number of Users Who Accessed Your Services', 143],
        ['Number of Users blocked for Attempted Fraud', 12], ['Newly Created Accounts', 118],
        ['Existing Accounts', 23], ['Identity Verified Users', 103], ['Newly Proofed Users', 83],
        ['Preverified Users', 20], ['Authentications', 1501], ['Account Creation', 1],
        ['Authentic Driver\'s License', 1], ['Facial Mismatch', 2],
        ['Invalid Attributes (DL, DOS)', 1], ['Identity Not Found (SSN / DOB / Deceased)', 3],
        ['Fraud Alert Detected', 1], ['Suspicious Phone', 1], ['Lacking Phone Ownership', 0],
        ['Wrong Phone Type', 0], ['Failed In-Person and Blocked', 1], ['Pending Fraud Review', 0],
        ['Adjudicated as Legitimate', 0], ['Preverified', 2], ['Remote Unattended', 61],
        ['In-Person Proofing', 3], ['Physical Letter', 9], ['Document Upload UX', 3],
        ['Selfie UX Issue', 1], ['Identity Resolution Attribute Mismatch', 2],
        ['Phone Number Record Check Failure', 1], ['Temporary Technical Issue', 0],
        ['Overall Proofing Success Rate', 0.914], ['Authentication Success', 0.9644],
        ['Path to Access Rate', 0.9259], ['Mobile', 0.036], ['Desktop', 0.964],
        ['Face / Touch', 0.0466], ['Authenticator App', 0.7561], ['PIV / CAC', 0.0068],
        ['SMS', 0.0709], ['Voice', 0.0], ['Backup Code', 0.0039], ['Security Key', 0.0],
        ['Personal Key', 0.0], ['Account Creation Success', 1.0]
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

    it '#rounded_percentage' do
      float0 = 0.672755877
      float1 = 0.3

      expect(subject.rounded_percentage(float0)).to eq(67.28)
      expect(subject.rounded_percentage(float1)).to eq(30.0)
    end

    it 'raises a NotImplementedError for #chart' do
      expect { subject.chart }.to raise_error(NotImplementedError)
    end

    it 'raises a NotImplementedError for #total' do
      expect { subject.total }.to raise_error(NotImplementedError)
    end
  end
end
