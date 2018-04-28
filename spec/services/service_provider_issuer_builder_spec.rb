require 'rails_helper'

describe ServiceProviderIssuerBuilder do
  describe '#build_issuer' do
    let(:service_provider) do
      build(
        :service_provider,
        issuer_department: 'ABC',
        issuer_app: 'app-name'
      )
    end

    context 'with saml protocol' do
      it 'builds a properly formatted issuer' do
        service_provider.identity_protocol = 'saml'
        issuer = ServiceProviderIssuerBuilder.new(service_provider).build_issuer

        expect(issuer).to eq(
          'urn:gov:gsa:SAML:2.0.profiles:sp:sso:ABC:app-name'
        )
      end
    end

    context 'with openid connect protocol' do
      it 'builds a properly formatted issuer' do
        service_provider.identity_protocol = 'openid_connect'
        issuer = ServiceProviderIssuerBuilder.new(service_provider).build_issuer

        expect(issuer).to eq(
          'urn:gov:gsa:openidconnect.profiles:sp:sso:ABC:app-name'
        )
      end
    end
  end
end
