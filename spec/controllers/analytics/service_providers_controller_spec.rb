require 'rails_helper'

RSpec.describe Analytics::ServiceProvidersController do
  let(:user) { create(:user, :logingov_admin) }
  let(:service_provider) { create(:service_provider) }

  before do
    sign_in(user)
  end

  describe '#show' do
    context 'available_reports' do
      let(:old_report) { AnalyticsReportStorage::ReportFile.new(key: 'old.json', last_modified: 2.days.ago) }
      let(:new_report) { AnalyticsReportStorage::ReportFile.new(key: 'new.json', last_modified: 1.day.ago) }
      let(:non_json) { AnalyticsReportStorage::ReportFile.new(key: 'readme.txt', last_modified: Time.current) }

      before do
        allow(AnalyticsReportStorage).to receive(:list).and_return([old_report, new_report,
                                                                    non_json])
      end

      it 'filters to only json files' do
        get :show, params: { id: service_provider.id }

        expect(assigns(:available_reports).map(&:key)).to_not include('readme.txt')
      end

      it 'sorts by last_modified descending' do
        get :show, params: { id: service_provider.id }

        expect(assigns(:available_reports).map(&:key)).to eq(['new.json', 'old.json'])
      end
    end

    context 'report_for_issuer' do
      let(:report_data) do
        [
          [{ 'issuer' => service_provider.issuer, 'count_users' => '100' }],
          [{ 'issuer' => 'other:issuer', 'count_users' => '50' }],
        ]
      end

      before do
        allow(AnalyticsReportStorage).to receive(:list).and_return([])
        allow(AnalyticsReportStorage).to receive(:fetch).and_return(report_data)
      end

      it 'returns nil when no report selected' do
        get :show, params: { id: service_provider.id }

        expect(assigns(:report_data)).to be_nil
      end

      it 'finds report matching service provider issuer' do
        get :show, params: { id: service_provider.id, report: 'test.json' }

        expect(assigns(:report_data)['issuer']).to eq(service_provider.issuer)
        expect(assigns(:report_data)['count_users']).to eq('100')
      end

      it 'returns nil when issuer not in report' do
        allow(AnalyticsReportStorage).to receive(:fetch).and_return(
          [[{ 'issuer' => 'other:issuer', 'count_users' => '50' }]],
        )

        get :show, params: { id: service_provider.id, report: 'test.json' }

        expect(assigns(:report_data)).to be_nil
      end
    end
  end
end
