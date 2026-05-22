require 'rails_helper'

describe Reports::Identity do
  before { Rails.cache.clear }

  let(:sp) { build(:service_provider) }

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
        [['Newly Proofed', 17], ['Preverified', 30]],
      )
    end
  end

  it 'skips invalid keys' do
    analytic = Analytic.new
    analytic.date = '2025-12-01'
    analytic.config = sp
    expected_count = rand(10..1000)
    storage_mock = instance_double(AnalyticsReportStorage)
    allow(AnalyticsReportStorage).to receive(:new)
      .with(sp.issuer, analytic.date)
      .and_return(storage_mock)
    allow(storage_mock).to receive(:fetch).and_return(
      { 'data' => {
        'count_stayed_blocked' => expected_count,
        'invalid_key' => rand(100..10_000),
        'count_other_invalid_key' => rand(10..1000),
      } },
    )
    subject = described_class.new(analytic)
    expect(subject.data).to eq(
      [[I18n.t('reports.count_stayed_blocked'), expected_count]],
    )
    expect(subject.fraud_data).to eq(
      [[I18n.t('reports.count_stayed_blocked'), expected_count]],
    )
  end

  describe '.available_dates' do
    it 'calls list once with all issuers' do
      sp1 = build(:service_provider, issuer: 'issuer_one')
      sp2 = build(:service_provider, issuer: 'issuer_two')

      allow(AnalyticsReportStorage).to receive(:list)
        .with(%w[issuer_one issuer_two])
        .and_return([])

      described_class.available_dates([sp1, sp2])

      expect(AnalyticsReportStorage).to have_received(:list).once
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
end
