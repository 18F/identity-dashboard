require 'rails_helper'

describe ToolsController do
  include Devise::Test::ControllerHelpers

  describe '#saml_request' do

    describe 'get' do
      before { get :saml_request }

      it 'validation_attempted is set as false' do
        expect(assigns[:validation_attempted]).to be false
      end

      it 'request is set to nil' do
        expect(assigns[:request]).to be nil
      end
    end

    describe 'post' do
      let(:saml_request) { double Tools::SAMLRequest }
      let(:params) {{ validation: { auth_url: 'url' } }}

      before do
        allow(Tools::SAMLRequest).to receive(:new) { saml_request }
        allow(saml_request).to receive(:run_validations)
        allow(saml_request).to receive(:valid)
      end

      it 'passes the validation params through' do
        p = ActionController::Parameters.new(params)
        validation_params = p.require(:validation).permit(:auth_url, :cert)
        expect(Tools::SAMLRequest).to receive(:new).with(validation_params) { saml_request}

        post :saml_request, params:
      end
    end
  end
end
