require 'rails_helper'

describe 'SamlRequest' do
  let(:cert) { build_pem(serial: 200) }
  let(:auth_url) { 'auth_url '}
  let(:params) { { auth_url:, cert: cert }.with_indifferent_access }
  subject(:request) { Tools::SamlRequest.new(params) }

  describe '#init' do
    it 'sets the attributes' do
      expect(subject.auth_url).to eq auth_url
      expect(subject.cert_body).to eq cert
      expect(subject.errors).to eq([])
    end
  end

  describe '#valid' do
    let(:decoded_request) { double SamlIdp::Request }
    let(:validity) { true }

    before do
      allow(SamlIdp::Request).to receive(:from_deflated_request)
      allow(decoded_request).to receive(:valid?) { validity }
    end

    describe 'when the request is valid' do
      it 'returns true' do
        expect(SamlIdp::Request).to receive(:from_deflated_request).with(
          auth_url, get_params: { SAMLRequest: auth_url }
        ) { decoded_request }

        expect(subject.valid).to be true
      end

      it 'only invokes from_deflated_request once' do
        expect(SamlIdp::Request).to receive(:from_deflated_request) { decoded_request }.once
        subject.valid
        subject.valid
      end
    end

    describe 'when the request is not valid' do
      let(:validity) { false }

      it 'returns false if' do
        expect(SamlIdp::Request).to receive(:from_deflated_request).with(
          auth_url, get_params: { SAMLRequest: auth_url }
        ) { decoded_request }

        expect(subject.valid).to be false
      end

      it 'only invokes from_deflated_request once' do
        expect(SamlIdp::Request).to receive(:from_deflated_request) { decoded_request }.once
        subject.valid
        subject.valid
      end
    end
  end

  describe '#valid_signature' do
    let(:decoded_request) { double SamlIdp::Request }
    let(:issuer) { '1234' }
    let(:sp) { SamlIdp::ServiceProvider.new }

    before do
      allow(SamlIdp::Request).to receive(:from_deflated_request) { decoded_request }
      allow(decoded_request).to receive(:issuer) { issuer }
      allow(decoded_request).to receive(:service_provider) { sp }
    end

    describe 'if there are no certs' do
      let(:cert) { '' }
      let(:issuer) { nil }

      it 'returns false' do
        expect(subject.valid_signature).to be false
      end

      it 'adds an error' do
        err = <<~EOS.squish
          Could not find any certificates to use. Please add a
          certificate to your application configuration or paste one below.
        EOS
        subject.valid_signature
        expect(subject.errors).to eq [err]
      end
    end

    describe 'if there is no Service Provider in the auth request' do
      before do
        allow(decoded_request).to receive(:service_provider) { nil }
      end

      it 'returns false' do
        expect(subject.valid_signature).to be false
      end

      it 'adds an error' do
        err = 'No matching Service Provider founded in this request. ' +
              'Please check issuer attribute.'
        subject.valid_signature
        expect(subject.errors).to eq [err]
      end
    end

    describe 'if a bad cert is passed in' do
      let(:cert) { 'i am not a cert!' }

      before do
        allow(decoded_request).to receive(:service_provider) { sp }
      end

      it 'returns false' do
        expect(subject.valid_signature).to be false
      end

      it 'adds an error' do
        subject.valid_signature
        expect(subject.errors).to eq ['Something is wrong with the certificate you submitted.']
      end
    end

    describe 'it is valid' do
      before do
        expect(decoded_request).to receive(:service_provider) { sp }
        expect(decoded_request).to receive(:matching_cert).and_return(cert)
      end

      it 'returns true' do
        expect(subject.valid_signature).to be true
      end

      it 'has no errors' do
        subject.valid_signature
        expect(subject.errors).to eq []
      end
    end
  end

  describe '#run_validations' do
    let(:decoded_request) { double SamlIdp::Request }
    let(:validity) { true }
    let(:sp) { SamlIdp::ServiceProvider.new }

    before do
      allow(SamlIdp::Request).to receive(:from_deflated_request) { decoded_request }
      allow(decoded_request).to receive(:service_provider) { sp }
      allow(decoded_request).to receive(:valid?) { validity }
    end

    describe 'when valid is false' do
      let(:validity) { false }

      it 'does not run the valid_signature methods' do
        expect(decoded_request).to_not receive(:service_provider)
        subject.run_validations
      end
    end

    describe 'when valid is true' do
      it 'runs valid_signature' do
        expect(decoded_request).to receive(:service_provider).and_return(nil)
        subject.run_validations
      end
    end

    describe '#xml' do
      let(:decoded_request) { double SamlIdp::Request }
      let(:raw_xml) { '<XMLtag />' }
      let(:xml) { Nokogiri::XML(raw_xml).to_xml }

      before do
        expect(SamlIdp::Request).to receive(:from_deflated_request) { decoded_request }
        expect(decoded_request).to receive(:raw_xml) { raw_xml }
      end

      it 'transforms the XML with Nokogiri correctly' do
        expect(subject.xml.inspect).to eq xml.inspect
      end
    end

    describe '#logout_request' do
      let(:decoded_request) { double SamlIdp::Request }

      before do
        allow(SamlIdp::Request).to receive(:from_deflated_request) { decoded_request }
      end

      describe 'it is a logout request' do
        before do
          expect(decoded_request).to receive(:logout_request?).and_return(true)
        end

        it 'returns true' do
          expect(subject.logout_request?).to be true
        end
      end

      describe 'it is not a logout request' do
        before do
          expect(decoded_request).to receive(:logout_request?).and_return(false)
        end

        it 'returns false' do
          expect(subject.logout_request?).to be false
        end
      end
    end
  end
end
