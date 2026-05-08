require 'rails_helper'

class MockReportIdentity
  def initialize(file_name)
    @test_data = JSON.parse(File.read(file_name))[0][0]
  end

  def report_information
    @test_data['report_information']
  end

  def provider_information
    @test_data['provider_information']
  end

  def data
    @test_data['data'].to_a.filter_map do |d|
      [I18n.t("reports.#{d[0]}"), d[1]]
    rescue I18n::MissingTranslationData
      next
    end
  end
end

describe AnalyticsReportCsv do
  let(:monthly_report) do
    MockReportIdentity.new(
      # rubocop:disable Layout/LineLength
      'spec/fixtures/reports/urn:gov:gsa:openidconnect.profiles:sp:sso:dol_ebsa:lfdb/monthly/2025-12-01 00:00:00.json',
      # rubocop:enable Layout/LineLength
    )
  end
  let(:subject) { described_class.new(monthly_report) }

  describe '#report_data_csv' do
    let(:exported_csv) { subject.report_data_csv }

    it 'outputs expected data' do
      csv = CSV.parse(exported_csv)
      expect(csv.length).to eq(39)
      expect(csv[0]).to eq(['', 'Quarterly', 'Monthly', 'Weekly'])
      expect(csv[1]).to eq(['Start Date', '', '2025-12-01 00:00:00', ''])
      expect(csv[2]).to eq(['Newly Created Accounts', '', '1173', ''])
      expect(csv[6]).to eq(['Inauthentic Doc.', '', '475', ''])
      expect(csv[30]).to eq(['Doc. Auth. Processing Issue', '', '2', ''])
      expect(csv[38]).to eq(['Personal Key', '', '0', ''])
    end
  end

  describe '#filename' do
    it 'provides a filename based on report contents' do
      expect(subject.filename).to eq('logingov_dol_lost_and_found_database_20251201.csv')
    end
  end
end
