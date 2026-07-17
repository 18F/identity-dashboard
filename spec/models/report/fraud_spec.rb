require 'rails_helper'

describe Report::Fraud do
  let(:test_data) do
    {
      'count_ssn_dob_deceased' => rand(1..1000),
      'count_suspicious_phone' => rand(1..1000),
      'count_inauthentic_doc' => rand(1..1000),
      # fraud review queue keys
      'count_pending_lg99_likely_fraud' => rand(1..1000),
      'count_pass_via_lg99' => rand(1..1000),
      # A valid key that is not a fraud key, so should get skipped over
      'count_preverified_users' => rand(1..1000),
    }
  end
  let(:mock_reports) do
    mock = instance_double(Reports)
    allow(mock).to receive(:data).and_return(test_data)
    mock
  end

  subject { described_class.new(mock_reports) }

  it '#total sums the fraud event data and nothing else' do
    expected_total = test_data.values_at(
      'count_ssn_dob_deceased',
      'count_suspicious_phone',
      'count_inauthentic_doc',
    ).sum
    expect(subject.total).to be(expected_total)
  end

  it 'can return #chart options with correct data' do
    expect(subject.chart).to eq({
      type: :bar_chart,
      title: 'Fraudsters Blocks',
      data: [
        ['Inauthentic Doc.', test_data['count_inauthentic_doc']],
        ['Rejected for Invalid SSN / DOB, or Deceased', test_data['count_ssn_dob_deceased']],
        ['Suspicious Phone', test_data['count_suspicious_phone']],
      ],
      options: { subtitle: 'Users blocked per outcome type' },
    })
  end

  it 'can return an accurate #review_queue_chart' do
    expect(subject.review_queue_chart).to eq({
      type: :bar_chart,
      title: 'Redress – Identity Verification',
      data: [
        ['Pending Fraud Review', test_data['count_pending_lg99_likely_fraud']],
        ['Adjudicated as Legitimate', test_data['count_pass_via_lg99']],
      ],
      options: {
        subtitle: 'Users who requested redress during this period',
        description: '"Adjudicated as legitimate" reflects cases where ' \
          'Login.gov reviewed the case and reversed the block.',
        colors: ['#ff580a', '#719f2a'],
      },
    })
  end

  describe 'with lots of data' do
    let(:test_data) do
      JSON.parse(Rails.root.join(
        'spec/fixtures/reports/4388/monthly/2025-04-01.json',
      ).read)['data']
    end

    it 'sorts #chart items in the same order as in FRAUD_KEYS' do
      expect(subject.chart[:data].map(&:first)).to eq(
        described_class::FRAUD_KEYS.map { |key| I18n.t("reports.#{key}") },
      )
    end
  end

  describe 'when numbers are nil' do
    let(:test_data) do
      JSON.parse(Rails.root.join(
        'spec/fixtures/reports/6236/monthly/2025-08-01.json',
      ).read)['data']
    end

    it 'returns a nil #total' do
      expect(subject.total).to be_nil
    end

    it 'has a #chart with empty data' do
      expect(subject.chart).to eq({
        type: :bar_chart,
        title: 'Fraudsters Blocks',
        data: [],
        options: { subtitle: 'Users blocked per outcome type' },
      })
    end

    it 'has a #review_queue_chart with empty data' do
      expect(subject.review_queue_chart).to eq({
        type: :bar_chart,
        title: 'Redress – Identity Verification',
        data: [],
        options: {
          subtitle: 'Users who requested redress during this period',
          # We skip the "adjudicated as legit" text when there's no "adjudicated" line in the chart
          colors: ['#ff580a', '#719f2a'],
        },
      })
    end
  end
end
