require 'rails_helper'

describe Reports::Identity do
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
        [['Newly Proofed', 17], ['Previously Verified', 30]],
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
end
