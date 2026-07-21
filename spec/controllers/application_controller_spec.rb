require 'rails_helper'

RSpec.describe ApplicationController do
  let(:user) { create(:user, uuid: SecureRandom.uuid) }
  let(:trace_id) { 'some-trace-id-abcdef' }

  before do
    allow(controller).to receive(:current_user).and_return(user)

    request.headers['X-Amzn-Trace-Id'] = trace_id
  end

  describe '#set_cache_headers' do
    controller do
      def index
        render plain: 'Test'
      end
    end

    it 'sets headers to disable cache' do
      request.path = '/logged-in'
      get :index

      expect(response.headers['Cache-Control']).to eq 'no-store'
      expect(response.headers['Pragma']).to eq 'no-cache'
    end

    it 'does not disable cache on the splash page' do
      request.path = '/'
      get :index

      expect(response.headers['Cache-Control']).to_not eq 'no-store'
      expect(response.headers['Pragma']).to_not eq 'no-cache'
    end
  end

  describe '#append_info_to_payload' do
    let(:payload) { {} }

    it 'adds user_uuid, user_agent and ip, trace_id to the lograge output' do
      controller.append_info_to_payload(payload)

      expect(payload).to eq(
        user_uuid: user.uuid,
        user_agent: request.user_agent,
        ip: request.remote_ip,
        host: request.host,
        trace_id: trace_id,
      )
    end

    context 'when there is no current_user' do
      let(:user) { nil }

      it 'logs a nil user_uuid' do
        controller.append_info_to_payload(payload)

        expect(payload).to include(user_uuid: nil)
      end
    end
  end

  context 'rescue' do
    let(:logger_double) { instance_double(EventLogger) }

    before do
      allow(logger_double).to receive(:unauthorized_access_attempt)
      allow(logger_double).to receive(:unpermitted_params_attempt)
      allow(EventLogger).to receive(:new).and_return(logger_double)
      allow(controller).to receive(:render)
    end

    describe '#log_not_auth_and_render_401' do
      it 'logs unauthorized exeptions' do
        controller.log_not_auth_and_render_401 'exception'

        expect(logger_double).to have_received(:unauthorized_access_attempt).with('exception')
      end
    end

    describe '#log_unperm_params_and_render_401' do
      it 'logs unpermitted params exeptions' do
        controller.log_unperm_params_and_render_401 'exception'

        expect(logger_double).to have_received(:unpermitted_params_attempt).with('exception')
      end
    end
  end

  context '#set_requested_url' do
    controller do
      def index
        render plain: 'Test'
      end
    end

    context 'when there is a current user' do
      it 'does not update the session' do
        get :index
        expect(controller.session[:requested_url]).to be nil
      end
    end

    context 'when there is no user' do
      let(:user) { nil }
      let(:requested_url) { 'http://localhost:3001/service_providers/1' }

      context 'when a session[:requested_url] is set' do
        before { controller.session[:requested_url] = requested_url }
        it 'does not update the session' do
          get :index
          expect(controller.session[:requested_url]).to eq requested_url
        end
      end

      context 'when there is no requested_url set' do
        it 'updates the session' do
          get :index
          expect(controller.session[:requested_url]).to_not be nil
          expect(controller.session[:requested_url]).to eq request.original_url
        end

        context 'when the request.original_url is the logged out state' do
          # the logout path returns a state param
          before do
            request.env['QUERY_STRING'] = 'state=whatever'
          end

          it 'does not update the session' do
            get :index
            expect(controller.session[:requested_url]).to be nil
          end
        end
      end
    end
  end
end
