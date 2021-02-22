require 'rails_helper'

RSpec.describe 'lograge' do
  describe 'custom payload' do
    let(:event) do
      ActiveSupport::Notifications::Event.new(
        'process_action.action_controller',
        start,
        finish,
        transaction_id,
        controller: 'HomeController',
        action: 'index',
        request: Rack::Request.new(headers),
        params: { foo: 'bar' },
        headers: headers,
        path: '/',
        response: instance_double(ActionDispatch::Response),
      )
    end

    let(:start) { Time.zone.now }
    let(:finish) { Time.zone.now }
    let(:transaction_id) { SecureRandom.uuid }
    let(:headers) { {} }

    let(:now) { Time.zone.now }

    it 'adds in timestamp, uuid, and pid and omits extra noise' do
      payload = Timecop.freeze(now) do
        Rails.application.config.lograge.custom_options.call(event)
      end

      expect(payload).to_not include(:params, :headers, :request, :response)

      expect(payload).to match(
        timestamp: now.iso8601,
        uuid: /\A[0-9a-f-]+\Z/, # rough UUID regex
        pid: Process.pid,
        controller: 'HomeController',
        action: 'index',
        path: '/',
      )
    end
  end
end
