require 'rails_helper'

describe Report::IdV do
  let(:mock_reports) do
    mock = instance_double(Reports)
    allow(mock).to receive(:data).and_return(test_data)
    mock
  end

  subject { described_class.new(mock_reports) }

  describe 'with valid data' do
    let(:test_data) do
      JSON.parse(Rails.root.join(
        'spec/fixtures/reports/v2/4388/monthly/2025-12-01.json',
      ).read)['data']
    end

    it 'returns a #proofing_success_chart' do
      expect(subject.proofing_success_chart).to eq({
        type: :pie_chart,
        data: [
          ['Pass', 91.4],
          ['Not Pass', 8.6],
        ],
        options: {
          colors: ['#18f', '#e21c3d'],
          title: 'Proofing Success Rate',
          description: 'Percentage of users who successfully completed identity verification ' \
            'credentials out of total users attempting, controlling for fraud and abandonment.',
          donut: true,
          suffix: '%',
          library: {
            title: { align: 'left' },
            subtitle: {
              align: 'left',
              text: 'Percentage of users who were successfully redirected to the application ' \
                'during this window',
            },
            accessibility: {
              screenReaderSection: {
                beforeChartFormat: '<h2>Proofing Success Rate</h2>',
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

    it 'returns a #access_path_chart' do
      expect(subject.access_path_chart).to eq({
        type: :bar_chart,
        data: [
          { name: 'Dead End', data: [['', 7.41]] },
          { name: 'Path Forward', data: [['', 92.59]] },
        ],
        options: {
          colors: ['#e21c3d', '#18f'],
          title: 'Path to Access Rate',
          description: 'This is counting 1 - (users who dead-ended / users who attempted). It ' \
            'shows, out of all users who attempted, who weren\'t dead-ended.',
          stacked: true,
          max: 100,
          suffix: '%',
          library: {
            title: { align: 'left' },
            subtitle: {
              align: 'left',
              text: 'Percentage of users who attempted verification, how many had a way forward ' \
                'during this window',
            },
            accessibility: {
              screenReaderSection: {
                beforeChartFormat: '<h2>Path to Access Rate</h2>',
              },
            },
            plotOptions: {
              series: {
                animation: false,
                colorByPoint: false,
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

    it 'returns a #channels_chart' do
      expect(subject.channels_chart).to eq({
        type: :pie_chart,
        data: [
          ['Remote Unattended', 81.33],
          ['Preverified', 2.67],
          ['In-Person Proofing', 4.0],
          ['Physical Letter', 12.0],
        ],
        options: {
          colors: ['#18f', '#e21c3d', '#f09436', '#40892d'],
          title: 'Identity Verification Channels',
          description: 'Channels through which users verified their identity credentials. ' \
            'Preverified = A user created a verification profile (passed proofing) elsewhere ' \
            'prior to this window. Remote unattended = Users who went through the online ' \
            'proofing process. IPP = users who completed their proofing process through in ' \
            'person verification. Physical letter = users who completed their address ' \
            'verification through receiving a letter from the Post Office.',
          donut: true,
          suffix: '%',
          library: {
            title: { align: 'left' },
            subtitle: {
              align: 'left',
              text: 'How users verified their identity during this window',
            },
            accessibility: {
              screenReaderSection: {
                beforeChartFormat: '<h2>Identity Verification Channels</h2>',
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

    it 'returns a #friction_chart' do
      expect(subject.friction_chart).to eq({
        type: :bar_chart,
        data: [
          ['Document Upload UX', 3],
          ['Selfie UX Issue', 1],
          ['Identity Resolution Attribute Mismatch', 2],
          ['Phone Number Record Check Failure', 1],
          ['Temporary Technical Issue', 0],
        ],
        options: {
          colors: ['#18f', '#e21c3d'],
          title: 'Points of User Friction',
          description: 'Counts represent users who hit given friction points across document ' \
            'authentication, identity resolution, and address verification steps and did not ' \
            'get past the block in the reporting window.',
          library: {
            title: { align: 'left' },
            subtitle: {
              align: 'left',
              text: 'Where users experienced the most difficulty completing verification ' \
                'during this window',
            },
            accessibility: {
              screenReaderSection: {
                beforeChartFormat: '<h2>Points of User Friction</h2>',
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

  describe 'with zeroed data' do
    let(:test_data) do
      {
        'pct_proofing_success' => 0,
        'pct_path_to_access' => 0,
        'count_pass_online_finalization' => 0,
        'count_skip_preverified_finalization' => 0,
        'count_pass_ipp' => 0,
        'count_pass_via_letter' => 0,
        'count_blocked_document_upload_ux' => 0,
        'count_selfie_ux' => 0,
        'count_identity_resolution_attribute_mismatch' => 0,
        'count_phone_number_record_check_failure' => 0,
        'count_temporary_technical_issues' => 0,
        # A valid key that does not count toward IdV data
        'count_auth_successful' => rand(0..100),
      }
    end

    it 'returns empty data in the #proofing_success_chart' do
      expect(subject.proofing_success_chart[:data]).to eq([])
    end

    it 'returns empty data in the #access_path_chart' do
      expect(subject.access_path_chart[:data]).to eq([])
    end

    it 'returns a #channels_chart' do
      expect(subject.channels_chart).to eq({
        type: :pie_chart,
        data: [
          ['Remote Unattended', 0],
          ['Preverified', 0],
          ['In-Person Proofing', 0],
          ['Physical Letter', 0],
        ],
        options: {
          colors: ['#18f', '#e21c3d', '#f09436', '#40892d'],
          title: 'Identity Verification Channels',
          description: 'Channels through which users verified their identity credentials. ' \
            'Preverified = A user created a verification profile (passed proofing) elsewhere ' \
            'prior to this window. Remote unattended = Users who went through the online ' \
            'proofing process. IPP = users who completed their proofing process through in ' \
            'person verification. Physical letter = users who completed their address ' \
            'verification through receiving a letter from the Post Office.',
          donut: true,
          suffix: '%',
          library: {
            title: { align: 'left' },
            subtitle: {
              align: 'left',
              text: 'How users verified their identity during this window',
            },
            accessibility: {
              screenReaderSection: {
                beforeChartFormat: '<h2>Identity Verification Channels</h2>',
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

    it 'returns a #friction_chart' do
      expect(subject.friction_chart).to eq({
        type: :bar_chart,
        data: [
          ['Document Upload UX', 0],
          ['Selfie UX Issue', 0],
          ['Identity Resolution Attribute Mismatch', 0],
          ['Phone Number Record Check Failure', 0],
          ['Temporary Technical Issue', 0],
        ],
        options: {
          colors: ['#18f', '#e21c3d'],
          title: 'Points of User Friction',
          description: 'Counts represent users who hit given friction points across document ' \
            'authentication, identity resolution, and address verification steps and did not ' \
            'get past the block in the reporting window.',
          library: {
            title: { align: 'left' },
            subtitle: {
              align: 'left',
              text: 'Where users experienced the most difficulty completing verification ' \
                'during this window',
            },
            accessibility: {
              screenReaderSection: {
                beforeChartFormat: '<h2>Points of User Friction</h2>',
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

  describe 'with nil data' do
    let(:test_data) do
      {
        'pct_proofing_success' => nil,
        'pct_path_to_access' => nil,
        'count_pass_online_finalization' => nil,
        'count_skip_preverified_finalization' => nil,
        'count_pass_ipp' => nil,
        'count_pass_via_letter' => nil,
        'count_blocked_document_upload_ux' => nil,
        'count_selfie_ux' => nil,
        'count_identity_resolution_attribute_mismatch' => nil,
        'count_phone_number_record_check_failure' => nil,
        'count_temporary_technical_issue' => nil,
        # A valid key that does not count toward IdV data
        'count_auth_successful' => rand(0..100),
      }
    end

    it 'returns empty data in the #proofing_success_chart' do
      expect(subject.proofing_success_chart[:data]).to eq([])
    end

    it 'returns empty data in the #access_path_chart' do
      expect(subject.access_path_chart[:data]).to eq([])
    end

    it 'returns empty data in the #channels_chart' do
      expect(subject.channels_chart[:data]).to eq([])
    end

    it 'returns empty data in the #friction_chart' do
      expect(subject.friction_chart[:data]).to eq([])
    end
  end
end
