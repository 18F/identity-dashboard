require 'rails_helper'

RSpec.describe Analytics do
  let(:path) { 'fake_path' }
  let(:uuid) { 'a2c4d6e8-1234-abcd-ab12-aa11bb22cc33' }
  let(:current_user) { create(:user, uuid: uuid) }
  let(:session) { {} }
  let(:logger) { instance_double(FakeLogger) }
  let(:analytics_attributes) do
    {
      path: path,
      event_properties: {},
    }.merge(request_attributes)
  end
  let(:request) { FakeRequest.new }
  let(:request_attributes) do
    {
      user_ip: FakeRequest.new.remote_ip,
      hostname: FakeRequest.new.host,
      user_agent: FakeRequest.new.user_agent,
      browser_name: 'Unknown Browser',
      browser_version: '0.0',
      browser_platform_name: 'Unknown',
      browser_platform_version: '0',
      browser_device_name: 'Unknown',
      browser_mobile: false,
      browser_bot: false,
    }
  end

  subject(:analytics) do
    Analytics.new(
      user: current_user,
      request: request,
      session: session,
      logger: logger,
    )
  end

  describe '#track_event' do
    it 'collects data and sends the event to the backend' do
      expect(logger).to receive(:track).with('Trackable Event',analytics_attributes)

      analytics.track_event('Trackable Event')
    end

    it 'does not track nil values' do
      expect(logger).to receive(:track).with('Trackable Event',analytics_attributes)

      analytics.track_event('Trackable Event', {example: nil})
    end
  end
end
