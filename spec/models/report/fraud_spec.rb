require 'rails_helper'

describe Report::Fraud do
  let(:test_data) do
    {
      'count_blocked_attempted_fraud' => rand(1..1000),
      'count_blocked_identity_not_found' => rand(1..1000),
      'count_suspicious_phone' => rand(1..1000),
      'count_blocked_authentic_drivers_license' => rand(1..1000),
      # fraud review queue keys
      'count_device_behavior_fraud_signals' => rand(1..1000),
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

  it '#total directly pulls from `count_blocked_attempted_fraud`' do
    expected_total = test_data['count_blocked_attempted_fraud']
    expect(subject.total).to be(expected_total)
  end

  it 'can return #chart options with correct data' do
    expect(subject.chart).to eq({
      type: :bar_chart,
      data: [
        ["Authentic Driver's License", test_data['count_blocked_authentic_drivers_license']],
        ['Identity Not Found (SSN / DOB / Deceased)',
         test_data['count_blocked_identity_not_found']],
        ['Suspicious Phone', test_data['count_suspicious_phone']],
      ],
      options: {
        colors: ['#1188ff', '#ff0000'],
        title: 'Fraudsters Blocked',
        library: {
          title: { align: 'left' },
          subtitle: {
            align: 'left',
            text: 'Users blocked per outcome type',
          },
          accessibility: {
            screenReaderSection: {
              beforeChartFormat: '<h2>Fraudsters Blocked</h2>',
            },
          },
          plotOptions: {
            series: {
              animation: false,
              colorByPoint: true,
            },
          },
          yAxis: {
            gridLineColor: '#888',
            minTickInterval: 1,
          },
        },
      },
    })
  end

  it 'can return an accurate #review_queue_chart' do
    expect(subject.review_queue_chart).to eq({
      type: :bar_chart,
      data: [
        ['Pending Fraud Review', test_data['count_device_behavior_fraud_signals']],
        ['Adjudicated as Legitimate', test_data['count_pass_via_lg99']],
      ],
      options: {
        description: '"Adjudicated as legitimate" reflects cases where ' \
          'Login.gov reviewed the case and reversed the block.',
        colors: ['#ff580a', '#719f2a'],
        title: 'Redress – Identity Verification',
        library: {
          title: { align: 'left' },
          subtitle: {
            align: 'left',
            text: 'Users who requested redress during this period',
          },
          accessibility: {
            screenReaderSection: {
              beforeChartFormat: '<h2>Redress – Identity Verification</h2>',
            },
          },
          plotOptions: {
            series: {
              animation: false,
              colorByPoint: true,
            },
          },
          yAxis: {
            gridLineColor: '#888',
            minTickInterval: 1,
          },
        },
      },
    })
  end

  describe 'with lots of data' do
    let(:test_data) do
      JSON.parse(Rails.root.join(
        'spec/fixtures/reports/v2/4388/monthly/2026-04-01.json',
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
        'spec/fixtures/reports/v2/6236/monthly/2025-08-01.json',
      ).read)['data']
    end

    it 'returns a nil #total' do
      expect(subject.total).to be_nil
    end

    it 'has a #chart with empty data' do
      expect(subject.chart).to eq({
        type: :bar_chart,
        data: [],
        options: {
          title: 'Fraudsters Blocked',
          colors: ['#1188ff', '#ff0000'],
          library: {
            title: { align: 'left' },
            subtitle: {
              align: 'left',
              text: 'Users blocked per outcome type',
            },
            accessibility: {
              screenReaderSection: {
                beforeChartFormat: '<h2>Fraudsters Blocked</h2>',
              },
            },
            plotOptions: {
              series: {
                animation: false,
                colorByPoint: true,
              },
            },
            yAxis: {
              gridLineColor: '#888',
              minTickInterval: 1,
            },
          },
        },
      })
    end

    it 'has a #review_queue_chart with empty data' do
      expect(subject.review_queue_chart).to eq({
        type: :bar_chart,
        data: [],
        options: {
          title: 'Redress – Identity Verification',
          colors: ['#ff580a', '#719f2a'],
          library: {
            title: { align: 'left' },
            subtitle: {
              align: 'left',
              text: 'Users who requested redress during this period',
            },
            accessibility: {
              screenReaderSection: {
                beforeChartFormat: '<h2>Redress – Identity Verification</h2>',
              },
            },
            plotOptions: {
              series: {
                animation: false,
                colorByPoint: true,
              },
            },
            yAxis: {
              gridLineColor: '#888',
              minTickInterval: 1,
            },
          },
        },
      })
    end
  end

  describe 'when passed review exists and pending fraud review is missing' do
    let(:test_data) do
      {
        'count_pass_via_lg99' => rand(1..1000),
      }
    end

    it 'returns an empty #review_queue_chart' do
      expect(subject.review_queue_chart[:data]).to eq([])
    end
  end

  describe 'when only passed review is missing and pending fraud review exists' do
    let(:test_data) do
      {
        'count_pending_lg99_likely_fraud' => rand(1..1000),
      }
    end

    it 'returns an empty #review_queue_chart' do
      expect(subject.review_queue_chart[:data]).to eq([])
    end
  end
end
