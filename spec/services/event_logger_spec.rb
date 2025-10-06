require 'rails_helper'
require 'time'

RSpec.describe EventLogger do
  subject(:log) do
    EventLogger.new(
      user:,
      request:,
      session:,
      logger:,
    )
  end

  let(:visit_id) { 'test_token' }
  let(:event_name) { 'Trackable Event' }
  let(:path) { 'fake_path' }
  let(:uuid) { 'a2c4d6e8-1234-abcd-ab12-aa11bb22cc33' }
  let(:user) { create(:user, uuid:) }
  let(:session) { { visit_token: visit_id } }
  let(:logger) { object_double(Rails.logger) }
  let(:request) { FakeRequest.new }
  let(:request_attributes) do
    {
      visit_id:,
      user_id: uuid,
      user_role: user&.primary_role&.name,
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
  let(:sp) { create(:service_provider) }

  describe '#track_event' do
    it 'collects data and sends the event to the backend' do
      expect(logger).to receive(:info).with(match(event_name))

      log.track_event('Trackable Event')
    end

    it 'does not track nil values' do
      expect(logger).to_not receive(:info).with(match('\"example\":nil'))

      log.track_event('Trackable Event', { example: nil })
    end
  end

  describe '#visit_token' do
    it 'returns the session visit_token' do
      expect(log.visit_token).to eq('test_token')
    end

    context 'when the session visit token is not set' do
      let(:log) do
        EventLogger.new(
          user:,
          request:,
          session: nil,
          logger:,
        )
      end

      before do
        allow(SecureRandom).to receive(:uuid).and_return('abcdef123456')
      end

      it 'generates a new visit token' do
        expect(log.visit_token).to eq('abcdef123456')
        expect(SecureRandom).to have_received(:uuid)
      end

      it 'only calls SecureRandom.uuid once' do
        2.times { log.visit_token }

        expect(SecureRandom).to have_received(:uuid).once
      end
    end
  end

  describe '#sp_created' do
    let(:name) { 'portal_sp_created' }
    let(:changes) do
      {
        id: sp.id,
        friendly_name: sp.friendly_name,
        team: sp.team&.name,
        created_at: sp.created_at.as_json,
        updated_at: sp.updated_at.as_json,
      }
    end

    it 'logs portal_sp_created event' do
      expect(logger).to receive(:info) do |data|
        obj = JSON.parse(data)
        expect(obj).to include(crud_properties(event_properties: { changes: }, name:)
          .deep_stringify_keys)
      end

      log.sp_created(changes:)
    end
  end

  describe '#sp_updated' do
    let(:name) { 'portal_sp_updated' }
    let(:changes) do
      {
        id: sp.id,
        friendly_name: sp.friendly_name,
        team: sp.team&.name,
        created_at: sp.created_at.as_json,
        updated_at: sp.updated_at.as_json,
      }
    end

    it 'logs portal_sp_updated event' do
      expect(logger).to receive(:info) do |data|
        obj = JSON.parse(data)
        expect(obj).to include(crud_properties(event_properties: { changes: }, name:)
          .deep_stringify_keys)
      end

      log.sp_updated(changes:)
    end
  end

  describe '#sp_destroyed' do
    let(:name) { 'portal_sp_destroyed' }
    let(:changes) { sp.to_json }

    it 'logs portal_sp_updated event' do
      expect(logger).to receive(:info) do |data|
        obj = JSON.parse(data)
        expect(obj).to include(crud_properties(event_properties: { changes: }, name:)
          .deep_stringify_keys)
      end

      log.sp_destroyed(changes:)
    end
  end

  describe '#team_created' do
    let(:team) { create(:team) }
    let(:name) { 'portal_team_created' }
    let(:changes) { team.to_json }

    it 'logs portal_team_created event' do
      expect(logger).to receive(:info) do |data|
        obj = JSON.parse(data)
        expect(obj).to include(crud_properties(event_properties: { changes: }, name:)
          .deep_stringify_keys)
      end

      log.team_created(changes:)
    end
  end

  describe '#team_updated' do
    let(:team) { create(:team) }
    let(:name) { 'portal_team_updated' }
    let(:changes) do
      {
        'name' => { old: team.name, new: 'New Team Name' },
        'id' => team.id,
      }
    end

    it 'logs portal_team_updated event' do
      expect(logger).to receive(:info) do |data|
        obj = JSON.parse(data)
        expect(obj).to include(crud_properties(event_properties: { changes: }, name:)
          .deep_stringify_keys)
      end

      log.team_updated(changes:)
    end
  end

  describe '#team_destroyed' do
    let(:team) { create(:team) }
    let(:name) { 'portal_team_destroyed' }
    let(:changes) { team.to_json }

    it 'logs portal_team_destroyed event' do
      expect(logger).to receive(:info) do |data|
        obj = JSON.parse(data)
        expect(obj).to include(crud_properties(event_properties: { changes: }, name:)
          .deep_stringify_keys)
      end

      log.team_destroyed(changes:)
    end
  end

  describe '#service_provider' do
    xit 'logs team_data when role_name is changed' do
      expect(logger).to receive(:info) do |data|
        obj = JSON.parse(data)
        expect(obj['properties']['event_properties']).to include('team', 'team_user')
      end

      team_membership = create(:team_membership)
      team_membership.role_name = 'partner_admin'
      team_membership.save

      log.record_save('update', team_membership)
    end
  end

  describe '#exception' do
    # See individual controller specs for integration tests

    it 'logs NotAuthorizedError exceptions' do
      options = {
        query: :TestMethod,
        record: User,
        policy: UserPolicy.new(user, User.new),
      }
      expect(logger).to receive(:info) do |data|
        obj = JSON.parse(data)
        expect(obj['properties']['event_properties']).to eq({
          'message' => 'not allowed to UserPolicy#TestMethod User',
          'query' => 'TestMethod',
          'record' => 'User',
          'policy' => 'UserPolicy',
        })
        expect(obj['name']).to eq('unauthorized_access_attempt')
      end

      log.unauthorized_access_attempt(
        Pundit::NotAuthorizedError.new(options),
      )
    end

    it 'logs UnpermittedParameters exceptions' do
      expect(logger).to receive(:info) do |data|
        obj = JSON.parse(data)
        expect(obj['properties']['event_properties']).to match({
          'message' => 'found unpermitted parameters: :one, :two',
          'params' => ['one', 'two'],
        })
        expect(obj['name']).to eq('unpermitted_params_attempt')
      end

      log.unpermitted_params_attempt(
        ActionController::UnpermittedParameters.new([:one, :two]),
      )
    end
  end

  def crud_properties(event_properties:, name:)
    request_attributes.merge({ name:, properties: { event_properties:, path: } })
  end
end
