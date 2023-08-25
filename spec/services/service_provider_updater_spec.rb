require 'rails_helper'

describe ServiceProviderUpdater do
  let(:connection) { Faraday.new }
  let(:url) { IdentityConfig.store.idp_sp_url }
  let(:token) { IdentityConfig.store.dashboard_api_token }
  let(:status) { 200 }
  let(:headers) do
    {
      'X-LOGIN-DASHBOARD-TOKEN' => token,
      'Content-Type' => 'gzip/json',
      'Content-Encoding' => 'gzip'
      }
  end

  before do
    stub_request(:post, url).
      with(headers:).
      to_return(status:)
  end

  describe '#ping' do
    context 'when a body is not passed through' do
      it 'returns status code 200 for success' do
        expect(ServiceProviderUpdater.ping).to eq 200
      end
    end

    context 'when a body is passed in' do
      let(:body) { {service_provider: {}} }

      it 'returns status code 200 for success' do
        expect(ServiceProviderUpdater.ping(body)).to eq 200
      end
    end

    context 'when the HTTP request fails' do
      let(:status) { 404 }

      it 'returns http status code for failure' do
        expect(ServiceProviderUpdater.ping).to eq 404
      end

      it 'notifies NewRelic of the error' do
        expect(::NewRelic::Agent).to receive(:notice_error)
        ServiceProviderUpdater.ping
      end
    end

    context 'when the HTTP request raises an error' do
      before do
        stub_request(:post, IdentityConfig.store.idp_sp_url).
          to_timeout
      end

      it 'returns http status code for failure' do
        expect(ServiceProviderUpdater.ping).to be nil
      end

      it 'notifies NewRelic of the error' do
        expect(::NewRelic::Agent).to receive(:notice_error)
        ServiceProviderUpdater.ping
      end
    end
  end
end
