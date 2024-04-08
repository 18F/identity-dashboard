require 'rails_helper'

RSpec.describe ApplicationController do
  let(:user) { create(:restricted_ic) }
  let(:trace_id) { 'some-trace-id-abcdef' }

  before do
    allow(controller).to receive(:current_user).and_return(user)

    request.headers['X-Amzn-Trace-Id'] = trace_id
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
      let(:current_user) { nil }

      it 'logs a nil user_uuid' do
        controller.append_info_to_payload(payload)

        expect(payload).to include(user_uuid: nil)
      end
    end
  end
end
