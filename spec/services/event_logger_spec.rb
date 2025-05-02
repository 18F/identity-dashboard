require 'rails_helper'
require 'time'

RSpec.describe EventLogger do
  let(:event_name) { 'Trackable Event' }
  let(:path) { 'fake_path' }
  let(:uuid) { 'a2c4d6e8-1234-abcd-ab12-aa11bb22cc33' }
  let(:current_user) { create(:user, uuid:) }
  let(:session) { { visit_token: 'test_token' } }
  let(:logger) { object_double(Rails.logger) }
  let(:time_now) { Time.zone.now() }
  let(:log_attributes) do
    {
      path: path,
      event_properties: {},
    }.merge(request_attributes)
  end
  let(:request) { FakeRequest.new }
  let(:request_attributes) do
    {
      log_filename: IdentityConfig.store.event_log_filename,
      visit_id: session[:visit_token],
      user_id: uuid,
      user_role: current_user&.primary_role&.name,
      name: event_name,
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
      time: time_now,
      event_id: 'test_event_id',
    }
  end

  subject(:log) do
    EventLogger.new(
      user: current_user,
      request: request,
      session: session,
      logger: logger,
    )
  end

  describe '#track_event' do
    it 'collects data and sends the event to the backend' do
      expect(logger).to receive(:info).with(match(event_name))

      log.track_event('Trackable Event')
    end

    it 'does not track nil values' do
      expect(logger).not_to receive(:info).with(match('\"example\":nil'))

      log.track_event('Trackable Event', { example: nil })
    end
  end
end
