require 'rails_helper'

class MockReportIdentity
  def initialize(file_name)
    @test_data = JSON.parse(File.read(file_name))
  end

  def report_information
    @test_data['report_information']
  end

  def provider_information
    @test_data['provider_information']
  end

  def data
    @test_data['data'].to_a.filter_map do |d|
      next unless I18n.exists?("reports.#{d[0]}")

      [I18n.t("reports.#{d[0]}"), d[1]]
    end
  end
end

describe AnalyticsReportCsv do
  let(:monthly_report) do
    MockReportIdentity.new(
      'spec/fixtures/reports/1939/monthly/2025-04-01.json',
    )
  end
  let(:subject) { described_class.new(monthly_report) }

  describe '#report_data_csv' do
    let(:exported_csv) { subject.report_data_csv }

    it 'outputs expected data' do
      csv = CSV.parse(exported_csv)
      expect(csv.length).to eq(39)
      expect(csv[0]).to eq(['', 'Quarterly', 'Monthly', 'Weekly'])
      expect(csv[1]).to eq(['Start Date', '', '20260401', ''])
      expect(csv[2]).to eq(['Newly Created Accounts', '', '39', ''])
      expect(csv[6]).to eq(['Inauthentic Doc.', '', nil, ''])
      expect(csv[30]).to eq(['Doc. Auth. Processing Issue', '', nil, ''])
      expect(csv[38]).to eq(['Personal Key', '', '0', ''])
    end

    it 'only outputs headers with blank data' do
      blank_report = Reports::Identity.new(Analytic.new)
      blank_subject = described_class.new(blank_report)
      csv = CSV.parse(blank_subject.report_data_csv)
      expect(csv.length).to be(1)
      expect(csv[0]).to eq(['', 'Quarterly', 'Monthly', 'Weekly'])
    end
  end

  describe '#filename' do
    it 'provides a filename based on report contents' do
      expect(subject.filename).to eq('logingov_fdms_sandbox_dev_20260401.csv')
    end
  end
end
