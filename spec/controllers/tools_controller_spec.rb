require 'rails_helper'

describe ToolsController do
  include Devise::Test::ControllerHelpers
  let(:user) { create(:user) }

  describe '#saml_request' do
    describe 'get' do
      before { get :saml_request }

      context 'a not logged in user' do
        it { is_expected.to redirect_to :root }
      end

      context 'a logged in user' do
        before do
          sign_in(user)
          get :saml_request
        end

        it { is_expected.to render_template :saml_request }
      end
    end
  end

  describe '#validate_saml_request' do
    let(:saml_request) { double Tools::SamlRequest }
    let(:params) {{ validation: { auth_url: 'url' } }}
    let(:logout_request) { false }

    context 'a not logged in user' do
      before do
        post :validate_saml_request, params:
      end

      it { is_expected.to redirect_to :root }
    end

    context 'a logged in user' do
      before do
        sign_in(user)
      end

      before do
        allow(Tools::SamlRequest).to receive(:new) { saml_request }
        allow(saml_request).to receive(:logout_request?) { logout_request }
        allow(saml_request).to receive(:run_validations)
        allow(saml_request).to receive(:valid)
        allow(saml_request).to receive(:issuer)
        post :validate_saml_request, params:
      end

      it 'passes the validation params through' do
        p = ActionController::Parameters.new(params)
        validation_params = p.require(:validation).permit(:auth_url, :cert)

        expect(Tools::SamlRequest).to have_received(:new).with(validation_params) { saml_request}
      end

      it 'validation_attempted is set as true' do
        expect(assigns(:validation_attempted)).to be true
      end

      describe 'if the request is a logout request' do
        let(:logout_request) { true }

        before { post :validate_saml_request, params: }

        it 'creates a flash warning' do
          msg = <<~EOS.squish
            You have passed a logout request. Currently, this tool is for
            Authentication requests only. Please try this
            <a href="https://www.samltool.com/validate_logout_req.php" target="_blank">tool</a>
            to validate logout requests.
          EOS

          expect(flash['warning']).to eq msg
        end

        it 'validation_attempted is set as false' do
          expect(assigns(:validation_attempted)).to be false
        end
      end
    end
  end
end
