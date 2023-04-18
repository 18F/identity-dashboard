require 'rails_helper'

describe ToolsController do
  include Devise::Test::ControllerHelpers

  describe '#index' do

    describe 'auth_url are not parseable' do
      let(:params) {{ auth_url: '' }}

      describe 'params[\'auth_url\'] is an empty string' do
        it 'creates a flash error' do
          get :index, params: params
          expect(flash['error']).to eq 'Please submit an auth URL or SAMLRequest to be validated.'
        end

        it 'instance variables are nil' do
          get :index, params: params
          expect(assigns[:valid_request]).to be nil
          expect(assigns[:valid_signature]).to be nil
          expect(assigns[:matching_cert_sn]).to be nil
        end

        it 'does not call SamlIdp:Request' do
          expect(SamlIdp::Request).not_to receive(:from_deflated_request)
          get :index, params: params
        end
      end
    end

    describe 'auth_url is not valid' do
      let(:params) { {auth_url: 'http://not-real!'} }
      before { get :index, params: params }

      describe 'no cert is passed through' do
        it 'creates a flash error' do
          expect(flash['error']).to eq 'Could not find any certificates to use. Please add a' \
                                       ' certificate to your application configuration or paste' \
                                       ' one below.'
        end

        it 'sets the instance variables to nil' do
          expect(assigns[:valid_request]).to be false
          expect(assigns[:valid_signature]).to be nil
          expect(assigns[:matching_cert_sn]).to be nil
        end
      end
    end

    describe 'auth_url is valid' do
      let(:saml_idp_request) { double SamlIdp::Request }

      describe 'a cert is not passed through the params' do
        let(:auth_url) { 'https://secure.login.gov/api/saml/auth2023?SAMLRequest=test&other_value=test_too'}
        let(:params) { { auth_url: auth_url }}

        before do
          expect(SamlIdp::Request).to receive(:from_deflated_request) { saml_idp_request }
          allow(saml_idp_request).to receive(:issuer)
          allow(saml_idp_request).to receive(:service_provider)
          allow(saml_idp_request).to receive(:valid?)
          allow(saml_idp_request).to receive(:raw_xml)
          get :index, params: params
        end

        describe 'the auth_url does not have an issuer' do
          it 'creates a flash error' do
            expect(flash['error']).to eq 'Could not find any certificates to use. Please add a' \
                                         ' certificate to your application configuration or paste' \
                                         ' one below.'
          end

          it 'sets the instance variables to nil' do
            expect(assigns[:valid_request]).to be nil
            expect(assigns[:valid_signature]).to be nil
            expect(assigns[:matching_cert_sn]).to be nil
          end

        end

        describe 'the auth_url request has an issuer' do
          let(:service_provider) { create(:service_provider, :saml) }

          before do
            allow(saml_idp_request).to receive(:issuer) { service_provider.issuer }
            get :index, params: params
          end

          describe 'the service_provider does not have a cert' do
            # this is the use case where there are no certs
            it 'creates a flash error' do
              expect(flash['error']).to eq 'Could not find any certificates to use. Please add a' \
                                           ' certificate to your application configuration or' \
                                           ' paste one below.'
            end

            it 'sets instance variables to whatever the SamlIdp::Request object returns' do
              expect(assigns[:valid_request]).to be nil
              expect(assigns[:valid_signature]).to be nil
              expect(assigns[:matching_cert_sn]).to be nil
            end

            describe 'the auth_request is valid' do
              # i am not sure if this test is worth doing as it's functionally the same as the
              # one before.
              before do
                allow(saml_idp_request).to receive(:valid?) { true }
              end

              it 'sets instance variables to whatever the SamlIdp::Request object returns' do
                get :index, params: params
                expect(assigns[:valid_signature]).to be nil
                expect(assigns[:matching_cert_sn]).to be nil
                expect(assigns[:valid_request]).to be true
              end
            end
          end

          describe 'the service_provider has a cert' do
            describe 'the cert is valid' do
              # dashboard has a validation for valid certs, so they are all valid.
              let(:cert) { build_pem }
              let(:service_provider) { create(:service_provider, :saml, certs: [cert]) }
              let(:saml_sp) { double SamlIdp::ServiceProvider }
              let(:actual_cert) { OpenSSL::X509::Certificate.new(cert) }

              before do
                allow(saml_idp_request).to receive(:service_provider) { saml_sp }
                allow(saml_idp_request).to receive(:options)
                allow(saml_sp).to receive(:valid_signature?) { true }
                allow(saml_sp).to receive(:certs=)
                allow(saml_sp).to receive(:matching_cert) { actual_cert }
                allow(saml_idp_request).to receive(:valid?) { true }
                allow(saml_idp_request).to receive(:raw_xml) { 'raw xml' }
                get :index, params: params
              end

              it 'does not create a flash error' do
                expect(flash['error']).to be nil
              end

              it 'sets instance variables to whatever the SamlIdp::Request object returns' do
                expect(assigns[:valid_signature]).to eq true
                expect(assigns[:matching_cert_sn]).to eq actual_cert.serial
                expect(assigns[:valid_request]).to be true
              end

            end
          end
        end
      end

      describe 'when a cert is passed through the params' do
        let(:auth_url) { 'https://secure.login.gov/api/saml/auth2023?SAMLRequest=test&other_value=test_too'}
        let(:cert) { build_pem }
        let(:saml_sp) { double SamlIdp::ServiceProvider }
        let(:actual_cert) { OpenSSL::X509::Certificate.new(cert) }
        let(:params) { { auth_url: auth_url, cert: cert }}

        before do
          allow(SamlIdp::Request).to receive(:from_deflated_request) { saml_idp_request }
          allow(saml_idp_request).to receive(:service_provider) { saml_sp }
          # :certs= represents a setter method here
          allow(saml_sp).to receive(:certs=)
          allow(saml_idp_request).to receive(:options)
          allow(saml_sp).to receive(:valid_signature?) { true }
          allow(saml_sp).to receive(:matching_cert) { actual_cert }
          allow(saml_idp_request).to receive(:valid?) { true }
          allow(saml_idp_request).to receive(:raw_xml) { 'raw xml' }
        end

        it 'there is no database call for ServiceProvider' do
          # i think it would be easier to avoid a DB call if we have a cert -- also
          # seems likely they want to use the cert they passed in for the validation
          expect(ServiceProvider).not_to receive(:find_by)

          get :index, params: params
        end

        describe 'the cert has an error' do
          let(:params) { { auth_url: auth_url, cert: 'bad cert' }}
          before do
            allow(saml_sp).to receive(:matching_cert)
            get :index, params: params
          end

          it 'creates a flash error' do
            expect(flash[:error]).to eq 'Something is wrong with the certificate you submitted.'
          end

          it 'sets instance variables to what is returned by SamlIDP::Request object' do
            # should the certs stuff do something different if the cert has an error?
            expect(assigns[:valid_signature]).to eq true
            expect(assigns[:matching_cert_sn]).to be nil
            expect(assigns[:valid_request]).to be true
          end
        end

        describe 'the cert is valid' do
          before do
            get :index, params: params
          end

          it 'does not create a flash error' do
            expect(flash['error']).to be nil
          end

          it 'sets instance variables to whatever the SamlIdp::Request object returns' do
            expect(assigns[:valid_signature]).to eq true
            expect(assigns[:matching_cert_sn]).to eq actual_cert.serial
            expect(assigns[:valid_request]).to be true
          end

        end
      end
    end
  end
end
