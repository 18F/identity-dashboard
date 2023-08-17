require 'rails_helper'

describe ServiceProviderUpdater do
  let(:status) { 200 }

  before do
    stub_request(:post, IdentityConfig.store.idp_sp_url).
      with(headers: { 'X-LOGIN-DASHBOARD-TOKEN' => IdentityConfig.store.dashboard_api_token }).
      to_return(status: status)
  end

  describe '#ping' do
    context 'when successful' do
      it 'returns status code 200 for success' do
        expect(ServiceProviderUpdater.ping).to eq 200
      end

      it 'does not pass a body through' do
        allow(Faraday).to receive(:post).and_call_original
        ServiceProviderUpdater.ping

        expect(Faraday).to have_received(:post).with(
          IdentityConfig.store.idp_sp_url,
          nil,
          { 'X-LOGIN-DASHBOARD-TOKEN' => IdentityConfig.store.dashboard_api_token }
        )
      end
    end

    context 'when a body is passed in' do
      it 'passes the body through the request' do
        allow(Faraday).to receive(:post).and_call_original
        ServiceProviderUpdater.ping({service_provider: {}})

        expect(Faraday).to have_received(:post).with(
          IdentityConfig.store.idp_sp_url,
          {service_provider: {}},
          { 'X-LOGIN-DASHBOARD-TOKEN' => IdentityConfig.store.dashboard_api_token }
        )
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
