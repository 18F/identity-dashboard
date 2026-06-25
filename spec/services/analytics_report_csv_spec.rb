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

  describe '#report_data_csv' do
    let(:exported_csv) { subject.report_data_csv }

    it 'outputs expected data' do
      csv = CSV.parse(exported_csv)
      expect(csv.length).to eq(39)
      expect(csv[0]).to eq(['', 'Quarterly', 'Monthly', 'Weekly'])
      expect(csv[1]).to eq(['Start Date', '', '2025-12-01', ''])
      expect(csv[2]).to eq(['Newly Created Accounts', '', '1173', ''])
      expect(csv[6]).to eq(['Inauthentic Doc.', '', '475', ''])
      expect(csv[30]).to eq(['Doc. Auth. Processing Issue', '', '2', ''])
      expect(csv[38]).to eq(['Personal Key', '', '0', ''])
    end

    it 'only outputs headers with blank data' do
      blank_report = Reports.new(Analytic.new)
      blank_subject = described_class.new(blank_report)
      csv = CSV.parse(blank_subject.report_data_csv)
      expect(csv.length).to be(1)
      expect(csv[0]).to eq(['', 'Quarterly', 'Monthly', 'Weekly'])
    end
  end

  describe '#filename' do
    it 'provides a filename based on report contents' do
      expect(subject.filename).to eq('logingov_dol_lost_and_found_database_20251201.csv')
    end
  end
end
