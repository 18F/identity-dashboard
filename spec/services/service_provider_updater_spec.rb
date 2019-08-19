require 'rails_helper'

describe ServiceProviderUpdater do
  let(:error_response) { instance_double(HTTParty::Response, body: 'Error!', code: 404) }

  describe '#ping' do
    context 'when successful' do
      it 'returns status code 200 for success' do
        expect(ServiceProviderUpdater.ping).to eq 200
      end
    end

    context 'when the HTTP request fails' do
      before do
        allow(::HTTParty).to receive(:post).and_return(error_response)
      end

      it 'returns http status code for failure' do
        expect(ServiceProviderUpdater.ping).to eq 404
      end

      it 'notifies NewRelic of the error' do
        expect(::NewRelic::Agent).to receive(:notice_error)
        ServiceProviderUpdater.ping
      end
    end
  end
end
