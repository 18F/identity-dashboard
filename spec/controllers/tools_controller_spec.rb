require 'rails_helper'

describe ToolsController do
  include Devise::Test::ControllerHelpers

  describe '#saml_request' do

    describe 'get' do
      before { get :saml_request }

      it 'validation_attempted is set as false' do
        expect(assigns(:validation_attempted)).to be false
      end

      it 'request is set to nil' do
        expect(assigns(:request)).to be nil
      end
    end

    describe 'post' do
      let(:saml_request) { double Tools::SAMLRequest }
      let(:params) {{ validation: { auth_url: 'url' } }}
      let(:logout_request) { false }

      before do
        allow(Tools::SAMLRequest).to receive(:new) { saml_request }
        allow(saml_request).to receive(:logout_request?) { logout_request }
        allow(saml_request).to receive(:run_validations)
        allow(saml_request).to receive(:valid)
        post :saml_request, params:
      end

      it 'passes the validation params through' do
        p = ActionController::Parameters.new(params)
        validation_params = p.require(:validation).permit(:auth_url, :cert)

        expect(Tools::SAMLRequest).to have_received(:new).with(validation_params) { saml_request}
      end

      it 'validation_attempted is set as true' do
        expect(assigns(:validation_attempted)).to be true
      end

      describe 'if the request is a logout request' do
        let(:logout_request) { true }

        before { post :saml_request, params: }

        it 'creates a flash warning' do
          msg = 'You have passed a logout request. Currently, this tool is for ' +
          'Authentication requests only. Please try this ' +
          '<a href="https://www.samltool.com/validate_logout_req.php" target="_blank">' +
          'tool</a> to authenticate logout requests'

          expect(flash['warning']).to eq msg
        end

        it 'validation_attempted is set as false' do
          expect(assigns(:validation_attempted)).to be false
        end
      end
    end
  end
end
