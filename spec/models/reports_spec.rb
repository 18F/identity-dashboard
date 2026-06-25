require 'rails_helper'

describe Reports do
  before { Rails.cache.clear }

  let(:sp) { build(:service_provider) }
  let(:logingov_admin) { create(:user, :logingov_admin) }

  context 'using local files for test data' do
    before do
      # Ensure the S3 config is invalid so the tests use the files on disk
      allow(IdentityConfig.store).to receive(:aws_reports_bucket).and_return(nil)
    end

    it 'works with test data' do
      analytic = Analytic.new
      analytic.config = build(
        :service_provider, issuer: 'urn:gov:gsa:openidconnect.profiles:sp:sso:dol_test'
      )
      analytic.date = '2025-12-01'
      subject = described_class.new(analytic)
      expect(subject.grand_total).to be(1519)
      expect(subject.idv_data).to eq(
        [['Newly Proofed', 17], ['Previously Proofed', 30]],
      )
    end
  end

  describe '.available_dates' do
    it 'calls list once with all issuers' do
      team = create(:team)
      sp1 = create(:service_provider, team:, issuer: 'issuer_one')
      sp2 = create(:service_provider, team:, issuer: 'issuer_two')
      create(:team_membership, user: logingov_admin, team:, role_name: 'partner_admin')

      allow(AnalyticsReportStorage).to receive(:list_by_issuer)
        .with(%w[issuer_one issuer_two])
        .and_return({})

      described_class.available_dates([sp1, sp2], logingov_admin)

      expect(AnalyticsReportStorage).to have_received(:list_by_issuer).once
    end
  end

  describe '#unwrap' do
    let(:analytic) { Analytic.new(date: '2025-12-01', config: sp) }
    let(:report_hash) { { 'data' => { 'count_newly_created_accounts' => 42 } } }
    let(:storage_mock) { instance_double(AnalyticsReportStorage) }

    before do
      allow(AnalyticsReportStorage).to receive(:new)
        .with(sp.issuer, '2025-12-01')
        .and_return(storage_mock)
    end

    it 'unwraps double-nested arrays' do
      allow(storage_mock).to receive(:fetch).and_return([[report_hash]])
      subject = described_class.new(analytic)
      expect(subject.grand_total).to eq(42)
    end

    it 'unwraps single-nested arrays' do
      allow(storage_mock).to receive(:fetch).and_return([report_hash])
      subject = described_class.new(analytic)
      expect(subject.grand_total).to eq(42)
    end

    it 'handles a flat hash' do
      allow(storage_mock).to receive(:fetch).and_return(report_hash)
      subject = described_class.new(analytic)
      expect(subject.grand_total).to eq(42)
    end

    it 'handles nil gracefully' do
      allow(storage_mock).to receive(:fetch).and_return(nil)
      subject = described_class.new(analytic)
      expect(subject.has_raw_data?).to be false
    end
  end

  describe '#has_raw_data?' do
    it 'returns true when report data is present' do
      analytic = Analytic.new(date: '2025-12-01', config: sp)
      storage_mock = instance_double(AnalyticsReportStorage)
      allow(AnalyticsReportStorage).to receive(:new)
        .with(sp.issuer, '2025-12-01')
        .and_return(storage_mock)
      allow(storage_mock).to receive(:fetch).and_return(
        [[{ 'data' => { 'count_stayed_blocked' => 1 } }]],
      )
      expect(described_class.new(analytic).has_raw_data?).to be true
    end

    it 'returns false when no report data is found' do
      analytic = Analytic.new(date: '2025-10-01', config: sp)
      storage_mock = instance_double(AnalyticsReportStorage)
      allow(AnalyticsReportStorage).to receive(:new)
        .with(sp.issuer, '2025-10-01')
        .and_return(storage_mock)
      allow(storage_mock).to receive(:fetch).and_return(nil)
      expect(described_class.new(analytic).has_raw_data?).to be false
    end
  end

  describe '#service_provider_name' do
    it 'returns the service provider name' do
      analytic = Analytic.new(date: '2025-12-01', config: sp)
      storage_mock = instance_double(AnalyticsReportStorage)
      allow(AnalyticsReportStorage).to receive(:new)
        .with(sp.issuer, '2025-12-01')
        .and_return(storage_mock)
      allow(storage_mock).to receive(:fetch).and_return(
        [[{ 'provider_information' => { 'service_provider_name' => sp.friendly_name } }]],
      )
      expect(described_class.new(analytic).service_provider_name).to eq(sp.friendly_name)
    end
  end

  describe '#report_information_present?' do
    it 'returns false when the report does not have header info' do
      analytic = Analytic.new(date: '2025-12-01', config: sp)
      storage_mock = instance_double(AnalyticsReportStorage)
      allow(AnalyticsReportStorage).to receive(:new)
        .with(sp.issuer, '2025-12-01')
        .and_return(storage_mock)
      allow(storage_mock).to receive(:fetch).and_return(
        [[{ 'report_information' => nil }]],
      )
      expect(described_class.new(analytic).report_information_present?).to be_falsey
    end

    it 'returns true when the report has header info' do
      analytic = Analytic.new(date: '2025-12-01', config: sp)
      storage_mock = instance_double(AnalyticsReportStorage)
      allow(AnalyticsReportStorage).to receive(:new)
        .with(sp.issuer, '2025-12-01')
        .and_return(storage_mock)
      allow(storage_mock).to receive(:fetch).and_return(
        [[{ 'report_information' => { period_calendar_id: 20251201 } }]],
      )
      expect(described_class.new(analytic).report_information_present?).to be_truthy
    end
  end

  describe '#formatted_period_start_date' do
    it 'returns the period start date in proper format' do
      analytic = Analytic.new(date: '2025-12-01', config: sp)
      storage_mock = instance_double(AnalyticsReportStorage)
      allow(AnalyticsReportStorage).to receive(:new)
        .with(sp.issuer, '2025-12-01')
        .and_return(storage_mock)
      allow(storage_mock).to receive(:fetch).and_return(
        [[{ 'report_information' => { 'period_start_date' => '2025-12-01 00:00:00 UTC' } }]],
      )
      expect(described_class.new(analytic).formatted_period_start_date).to eq('2025-12-01')
    end
  end

  describe '#period_calendar_id' do
    it 'returns the calendar ID for the selected period' do
      analytic = Analytic.new(date: '2025-12-01', config: sp)
      storage_mock = instance_double(AnalyticsReportStorage)
      allow(AnalyticsReportStorage).to receive(:new)
        .with(sp.issuer, '2025-12-01')
        .and_return(storage_mock)
      allow(storage_mock).to receive(:fetch).and_return(
        [[{ 'report_information' => { 'period_calendar_id' => 20251201 } }]],
      )
      expect(described_class.new(analytic).period_calendar_id).to eq(20251201)
    end
  end

  # context 'when numbers are nil' do
  #   let(:issuer_with_null_stats) { 'urn:gov:gsa:SAML:2.0.profiles:sp:sso:gsa:deleteme' }
  #   let(:sp) { create(:service_provider, :ready_to_activate, issuer: issuer_with_null_stats) }
  #   let(:analytic) do
  #     Analytic.new.tap do |a|
  #       # This should map to `spec/fixtures/reports/6236/monthly/2025-08-01.json` which
  #       # has all fields present but with values set to `null`
  #       a.date = '2025-08-01'
  #       a.config = sp
  #     end
  #   end
  #   let(:subject) { described_class.new(analytic) }

  #   it 'returns nil for #grand_total' do
  #     expect(subject.grand_total).to be_nil
  #   end

  #   it 'returns nil for #fraud_total' do
  #     expect(subject.fraud_total).to be_nil
  #   end

  #   it 'returns nil for #successful_auths' do
  #     expect(subject.successful_auths).to be_nil
  #   end

  #   it 'returns an empty array for idv_data' do
  #     expect(subject.idv_data).to eq([])
  #   end

  #   it 'returns an empty array for usage_data' do
  #     expect(subject.usage_data).to eq([])
  #   end
  # end
end
