require 'rails_helper'

describe ToolsController do
  include Devise::Test::ControllerHelpers

  describe "#index" do
    before { get :index, params: params }

    describe "auth_url are not parseable" do
      
      describe "params['auth_url'] is an empty string" do
        let(:params) { { auth_url: '' } }
        
        it "creates a flash error" do
          expect(flash["error"]).to eq "Please submit an auth URL to be validated."
        end

        it "instance variables are nil" do
          expect(@valid_request).to be nil
          expect(@valid_signature).to be nil
          expect(@matching_cert_sn).to be nil
        end

        it 'does not call SamlIdp:Request' do
          expect(SamlIdp::Request).not_to have_received(:from_deflated_request)
        end
      end

      describe "params['auth_url'] is not a url" do
        let(:params) { {auth_url: "i am not a url!"} }
 
        it "creates a flash error" do
          # is that what we want here? do we want a flash error?
          expect(flash["error"]).to eq "Please submit an auth URL to be validated."
        end

        it "instance variables are nil" do
          expect(@valid_request).to be nil
          expect(@valid_signature).to be nil
          expect(@matching_cert_sn).to be nil
        end

        it 'does not call SamlIdp:Request' do
          expect(SamlIdp::Request).not_to have_received(:from_deflated_request)
        end
      end
    end

    describe "auth_url is not valid" do
      before { get :index, params: params }
      
      describe 'no cert is passed through' do
        let(:params) { {auth_url: "http://not-real!"} }

        it "creates a flash error" do
          expect(flash["error"]).to eq "Could not find any certificates to use. Please add a certificate to your application configuration or paste one below."
        end

        it "sets the instance variables to nil" do
          expect(@valid_request).to be nil
          expect(@valid_signature).to be nil
          expect(@matching_cert_sn).to be nil
        end
      end
    end

    describe "auth_url is valid" do
      let(:saml_idp_request) { double SamlIdp::Request }

      describe "a cert is not passed through the params" do
        let(:auth_url) { "https://secure.login.gov/api/saml/auth2023?SAMLRequest=test&other_value=test_too"}
        let(:params) { { auth_url:  auth_url }}

        describe "the auth_url does not have an issuer" do
          # there are no certs 

          it "creates a flash error" do
            # expect(SamlIdp::Request).to receive(:from_deflated_request).and_return saml_idp_request
            # expect(saml_idp_request).to receive(:issuer).and_return nil
            expect(flash["error"]).to eq "Could not find any certificates to use. Please add a certificate to your application configuration or paste one below."
          end
  
          it "sets the instance variables to nil" do
            expect(@valid_request).to be nil
            expect(@valid_signature).to be nil
            expect(@matching_cert_sn).to be nil
          end
          
        end
        
        describe "the service_provider does not have a cert" do
          let(:service_provider) { create(:service_provider, :saml)}
          # is it possible for a valid auth_url request to not return an issuer:?
          # this is the use case where there are no certs
          it "adds a flash error" do
          end

          it "sets @valid_signature and @matching_cert_sn to nil" do
          end

          it "sets @valid_request to true" do
          end
        end

        describe "the auth_url request has an issuer" do
          describe "the service_provider does not have any certs" do
            it "adds a flash error" do
            end

            it "sets @valid_signature and @matching_cert_sn to nil" do
            end

            it "sets @valid_request to true" do
            end
          end

          describe "the service_provider has a cert" do
            describe "the cert has an error" do
              it "creates a flash error" do
                # do we want to do a different flash error if the error comes from an 
                # auth_url? "you submitted" is confusing language for that use case
              end
              
              it "sets @valid_signature and @matching_cert_sn to nil" do
              end

              it "sets @valid_request to true" do
              end
            end

            describe "the cert is valid" do
              let(:cert) { build_pem }
              it "does not create a flash error" do
              end

              it "sets @valid_request and @valid_signature to true" do
              end

              it "sets matching_cert_sn to the correct value" do
              end

              it "returns expected XML" do
              end
            end
          end

          describe "the service provider has multiple certs" do
            # these cases are a little hazy to me -- how is this picking the correct cert?
            it "picks a valid cert" do
            end
          end
        end
      end

      describe "when a cert is passed through the params" do
        it "there is no database call for ServiceProvider" do
          # i think it would be easier to avoid a DB call if we have a cert -- also
          # seems likely they want to use that cert for the validation
        end

        describe "the cert has an error" do
          it "creates a flash error" do
            # do we want to do a different flash error if the error comes from an 
            # auth_url? "you submitted" is confusing language for that use case
          end
          
          it "sets @valid_signature and @matching_cert_sn to nil" do
          end

          it "sets @valid_request to true" do
          end
        end

        describe "the cert is valid" do
          it "does not create a flash error" do
          end

          it "sets @valid_request and @valid_signature to true" do
          end

          it "sets matching_cert_sn to the correct value" do
          end

          it "returns expected XML" do
          end
        end
      end
    end
  end
end