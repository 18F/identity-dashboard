require 'rails_helper'

describe ToolsController do
  include Devise::Test::ControllerHelpers

  describe "#index" do

    describe "auth_url are not parseable" do
      describe "no params['auth_url']" do
        it "returns nil" do
          get :index
          expect(response).to be nil
          # is that what we want here?
        end

        describe "params['auth_url'] is not a url" do
          it "returns nil" do
            # is that what we want here?
          end
        end
      end
    end

    describe "auth_url is not valid" do
      let(:params) { {auth_url: "http://not-real!"} }
      it "sets the instance variables to nil" do
        get :index, params: params
        expect(flash["error"]).to eq "Could not find any certificates to use. Please add a certificate to your application configuration or paste one below."
        expect(@valid_request).to be nil
        # etc etc
      end
    end

    describe "auth_url is valid" do
      describe "a cert is not passed through the params" do
        describe "the auth_url request does not have an issuer" do
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