require 'rails_helper'

class MockAnalytic
  def initialize(data)
    @data = data
  end

  def config
    MockAnalytic.new(@data)
  end

  def issuer
    @data['issuer']
  end

  def date
    @data['report_information']['period_start_date']
  end

  def date_valid?
    /\d{4}-\d{2}-\d{2}/.match? date
  end
end

def mock_report_identity(file_name)
  test_data = JSON.parse(File.read(file_name))

  Reports.new(MockAnalytic.new(test_data))
end

describe AnalyticsReportCsv do
  let(:monthly_report) do
    mock_report_identity(
      'spec/fixtures/reports/4388/monthly/2025-12-01.json',
    )
  end
  let(:subject) { described_class.new(monthly_report) }

  before do
    Rails.cache.delete('analytics_issuer_to_id_map')
  end

  describe '#report_data_csv' do
    let(:exported_csv) { subject.report_data_csv }

    it 'outputs expected data' do
      csv = CSV.parse(exported_csv)
      expect(csv.length).to eq(45)
      expect(csv[0]).to eq(['', 'Description', 'Quarterly', 'Monthly', 'Weekly'])
      expect(csv[1]).to eq(['Start Date', 'First day of the reporting month', '', '2025-12-01', ''])
      expect(csv[2]).to eq(
        [
          'Number of Users Who Accessed Your Services',
          'Total number of users that accessed services via Login.gov',
          '',
          '143',
          '',
        ],
      )
      expect(csv[6]).to eq(
        [
          'Identity Verified Users',
          'Total number of identity verified users (new and preverified)',
          '',
          '103',
          '',
        ],
      )
      expect(csv[29][0]).to eq('Phone Number Record Check Failure')
      expect(csv[29][3]).to eq('1')
      expect(csv[39]).to eq(
        ['SMS', 'Proportion of successful authentications using SMS', '', '0.0709', ''],
      )
    end

    context 'when a metric has no description' do
      before do
        I18n.backend.eager_load!
        I18n.backend.store_translations(:en, reports: { descriptions: { count_active_users: nil } })
      end

      after { I18n.reload! }

      it 'leaves the description blank' do
        csv = CSV.parse(exported_csv)
        expect(csv[2]).to eq(['Number of Users Who Accessed Your Services', '', '', '143', ''])
      end
    end

    it 'only outputs headers with blank data' do
      blank_report = Reports.new(Analytic.new)
      blank_subject = described_class.new(blank_report)
      csv = CSV.parse(blank_subject.report_data_csv)
      expect(csv.length).to be(1)
      expect(csv[0]).to eq(['', 'Description', 'Quarterly', 'Monthly', 'Weekly'])
    end
  end

  describe '#filename' do
    it 'provides a filename based on report contents' do
      expect(subject.filename).to eq('logingov_dol_lost_and_found_database_20251201.csv')
    end
  end
end
