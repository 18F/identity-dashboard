require 'rails_helper'

describe Reports::IdV do
  let(:mock_reports) do
    mock = instance_double(Reports)
    allow(mock).to receive(:data).and_return(test_data)
    mock
  end

  subject { described_class.new(mock_reports) }

  describe 'with valid data' do
    let(:test_data) do
      {
        'count_newly_proofed_users' => rand(1..1000),
        'count_preverified_users' => rand(1..1000),
        # A valid key that does not count toward IdV data
        'count_auth_successful' => rand(1..1000),
      }
    end

    it 'returns a #chart' do
      expect(subject.chart).to eq({
        type: :column_chart,
        data: [
          [I18n.t('reports.count_newly_proofed_users'), test_data['count_newly_proofed_users']],
          [I18n.t('reports.count_preverified_users'), test_data['count_preverified_users']],
        ],
        title: 'Active Identity Verified Users',
        options: {
          subtitle: 'Unique users who accessed a service requiring verification',
          description: 'Newly proofed are net new users who verified during this window. ' \
          'Previously proofed are users who completed verification ahead of this window,',
        },
      })
    end
  end

  describe 'with zeroed data' do
    let(:test_data) do
      {
        'count_newly_proofed_users' => 0,
        'count_preverified_users' => 0,
        # A valid key that does not count toward IdV data
        'count_auth_successful' => rand(0..100),
      }
    end

    it 'returns a #chart' do
      expect(subject.chart).to eq({
        type: :column_chart,
        data: [
          [I18n.t('reports.count_newly_proofed_users'), 0],
          [I18n.t('reports.count_preverified_users'), 0],
        ],
        title: 'Active Identity Verified Users',
        options: {
          subtitle: 'Unique users who accessed a service requiring verification',
          description: 'Newly proofed are net new users who verified during this window. ' \
          'Previously proofed are users who completed verification ahead of this window,',
        },
      })
    end
  end

  describe 'with nil data' do
    let(:test_data) do
      {
        'count_newly_proofed_users' => nil,
        'count_preverified_users' => nil,
        # A valid key that does not count toward IdV data
        'count_auth_successful' => rand(0..100),
      }
    end

    it 'returns empty data in the #chart' do
      expect(subject.chart[:data]).to eq([])
    end
  end
end
