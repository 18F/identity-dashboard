require 'rails_helper'

describe AnalyticsReportCsv do
  let(:monthly_report) do
    JSON.parse(
      File.read(
        # rubocop:disable Layout/LineLength
        'spec/fixtures/reports/urn:gov:gsa:openidconnect.profiles:sp:sso:dol_ebsa:lfdb/monthly/2025-12-01 00:00:00.json',
        # rubocop:enable Layout/LineLength
      ),
    )[0][0]
  end
  let(:subject) { described_class.new(monthly_report) }

  describe '#report_data_csv' do
    let(:exported_csv) { subject.report_data_csv }

    it 'outputs expected data' do
      csv = CSV.parse(exported_csv)
      expect(csv.length).to eq(27)
      expect(csv[0]).to eq(['', 'Quarterly', 'Monthly', 'Weekly'])
      expect(csv[1]).to eq(['Start Date', '', '2025-12-01 00:00:00', ''])
      expect(csv[2]).to eq(['Inauthentic Doc.', '', '475', ''])
      expect(csv[26]).to eq(['Doc. Auth. Processing Issue', '', '2', ''])
    end
  end

  describe '#filename' do
    it 'provides a filename based on report contents' do
      expect(subject.filename).to eq('logingov_dol_lost_and_found_database_20251201.csv')
    end
  end
end
