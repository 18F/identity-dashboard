require 'rails_helper'

describe Reports::Identity do
  let(:sp) { build(:service_provider) }

  it 'skips invalid keys' do
    analytic = Analytic.new
    analytic.date = '2025-12-01 00:00:00'
    analytic.config = sp
    expected_count = rand(10..1000)
    storage_mock = instance_double(AnalyticsReportStorage)
    allow(AnalyticsReportStorage).to receive(:new)
      .with(sp.issuer, analytic.date)
      .and_return(storage_mock)
    allow(storage_mock).to receive(:fetch).and_return(
      [[
        { 'data' => {
          'count_stayed_blocked' => expected_count,
          'invalid_key' => rand(100..10_000),
          'count_other_invalid_key' => rand(10..1000),
        } },
      ]],
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
