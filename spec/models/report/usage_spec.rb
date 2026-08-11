require 'rails_helper'

describe Report::Usage do
  let(:mock_reports) do
    mock = instance_double(Reports)
    allow(mock).to receive(:data).and_return(test_data)
    mock
  end

  subject { described_class.new(mock_reports) }

  describe 'with valid data' do
    let(:test_data) do
      {
        'count_active_users' => rand(1..1000),
        'count_newly_created_accounts' => rand(1..1000),
        'count_auth_successful' => rand(1..1000),
        'count_newly_proofed_users' => rand(1..1000),
        'count_preverified_users' => rand(1..1000),
        # A valid key that does not count toward usage or IdV
        'count_inauthentic_doc' => rand(1..1000),
      }
    end

    it 'returns a #total' do
      expect(subject.total).to eq(test_data['count_active_users'])
    end

    it 'returns #succesful_auths' do
      expect(subject.successful_auths).to eq(test_data['count_auth_successful'])
    end

    it 'returns an #overall_chart' do
      expect(subject.overall_chart).to eq({
        type: :column_chart,
        data: [
          [I18n.t('reports.count_newly_created_accounts'),
           test_data['count_newly_created_accounts']],
        ],
        options: {
          description: 'New accounts reflect account creation during this window. ' \
                          'Existing accounts reflect accounts created ahead of this window.',
          colors: ['#18f'],
          title: 'All Active Users',
          library: {
            title: { align: 'left' },
            subtitle: {
              align: 'left',
              text: 'Unique users who accessed a service',
            },
            accessibility: {
              screenReaderSection: {
                beforeChartFormat: '<h2>All Active Users</h2>',
              },
            },
            plotOptions: {
              bar: {
                animation: false,
                colorByPoint: true,
              },
              column: {
                animation: false,
                colorByPoint: true,
              },
              pie: {
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

    it 'returns an #idv_chart' do
      expect(subject.idv_chart).to eq({
        type: :column_chart,
        data: [
          [I18n.t('reports.count_newly_proofed_users'), test_data['count_newly_proofed_users']],
          [I18n.t('reports.count_preverified_users'), test_data['count_preverified_users']],
        ],
        options: {
          colors: ['#18f'],
          title: 'Active Identity Verified Users',
          description: 'Newly proofed are net new users who verified during this window. ' \
          'Previously proofed are users who completed verification ahead of this window,',
          library: {
            title: { align: 'left' },
            subtitle: {
              align: 'left',
              text: 'Unique users who accessed a service requiring verification',
            },
            accessibility: {
              screenReaderSection: {
                beforeChartFormat: '<h2>Active Identity Verified Users</h2>',
              },
            },
            plotOptions: {
              bar: {
                animation: false,
                colorByPoint: true,
              },
              column: {
                animation: false,
                colorByPoint: true,
              },
              pie: {
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

  describe 'with nil data' do
    let(:test_data) do
      {
        'count_newly_created_accounts' => nil,
        'count_existing_accounts' => nil,
        'count_auth_successful' => nil,
        # A valid key that does not count toward usage
        'count_inauthentic_doc' => rand(1..1000),
      }
    end

    it 'returns a nil #total' do
      expect(subject.total).to be_nil
    end

    it 'returns nil #succesful_auths' do
      expect(subject.total).to be_nil
    end

    it 'returns an empty #overall_chart' do
      expect(subject.overall_chart[:data]).to eq([])
    end

    it 'returns an empty #idv_chart' do
      expect(subject.idv_chart[:data]).to eq([])
    end
  end

  describe 'with zeroed data' do
    let(:test_data) do
      {
        'count_active_users' => 0,
        'count_newly_created_accounts' => 0,
        'count_existing_accounts' => 0,
        'count_auth_successful' => 0,
        'count_newly_proofed_users' => 0,
        'count_preverified_users' => 0,
        # A valid key that does not count toward usage
        'count_inauthentic_doc' => rand(0..1000),
      }
    end

    it 'returns a zero #total' do
      expect(subject.total).to be(0)
    end

    it 'returns zero #successful_auths' do
      expect(subject.successful_auths).to be(0)
    end

    it 'returns a zeroed #overall_chart' do
      expect(subject.overall_chart[:data]).to eq(
        [
          [I18n.t('reports.count_newly_created_accounts'), 0],
          [I18n.t('reports.count_existing_accounts'), 0],
        ],
      )
    end

    it 'returns a zeroed #idv_chart' do
      expect(subject.idv_chart).to eq({
        type: :column_chart,
        data: [
          [I18n.t('reports.count_newly_proofed_users'), 0],
          [I18n.t('reports.count_preverified_users'), 0],
        ],
        options: {
          colors: ['#18f'],
          title: 'Active Identity Verified Users',
          description: 'Newly proofed are net new users who verified during this window. ' \
          'Previously proofed are users who completed verification ahead of this window,',
          library: {
            title: { align: 'left' },
            subtitle: {
              align: 'left',
              text: 'Unique users who accessed a service requiring verification',
            },
            accessibility: {
              screenReaderSection: {
                beforeChartFormat: '<h2>Active Identity Verified Users</h2>',
              },
            },
            plotOptions: {
              bar: {
                animation: false,
                colorByPoint: true,
              },
              column: {
                animation: false,
                colorByPoint: true,
              },
              pie: {
                animation: false,
                colorByPoint: true,
              }
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
end
