require 'rails_helper'

RSpec.describe Airtable, type: :model do
  let(:user_uuid) { 'test-user-uuid' }
  let(:airtable) { Airtable.new(user_uuid) }
  let(:sample_record) { { 'fields' => { 'Partner Portal Admin' => ['admin_id_1', 'admin_id_2'] } } }
  let(:sample_email) { 'admin@example.com' }
  let(:token_response) do
    {
      'access_token' => 'mock_access_token',
      'expires_in' => 3600,
      'refresh_token' => 'mock_refresh_token',
      'refresh_expires_in' => 7200,
    }.to_json
  end

  describe '#get_matching_records' do
    it 'retrieves matching records' do
      issuers = ['Issuer 1', 'Issuer 2']
      user_token = 'mocked_token'
      REDIS_POOL.with do |redis|
        redis.setex("#{user_uuid}.airtable_oauth_token", 3600.seconds, user_token)
      end

      response_body = {
        'records' => [
          { 'fields' => { 'Issuer String' => 'Issuer 1' } },
          { 'fields' => { 'Issuer String' => 'Issuer 3' } },
        ],
        'offset' => nil,
      }.to_json

      # Include the missing headers in the request stub
      app_id = IdentityConfig.store.airtable_app_id
      table_id = IdentityConfig.store.airtable_table_id

      stub_request(:get, "https://api.airtable.com/v0/#{app_id}/#{table_id}?offset=").
        with(
          headers: {
            'Accept' => '*/*',
         'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
         'Authorization' => 'Bearer mocked_token',
         'Content-Type' => 'application/x-www-form-urlencoded',
         'User-Agent' => 'Ruby',
          },
        ).
        to_return(status: 200, body: response_body, headers: {})

      records = airtable.get_matching_records(issuers)

      expect(records.size).to eq(1)
      expect(records.first['fields']['Issuer String']).to eq('Issuer 1')
    end
  end

  describe '#new_partner_admin_in_airtable?' do
    let(:sample_record) do
      { 'id' => "rec#{SecureRandom.hex(10)}",
        'createdTime' => Time.zone.now,
        'fields' => { 'Issuer String' => 'urn:gov:gsa:SAML:2.0.profiles:sp:sso:example:issuer',
                      'Applications' => ["rec#{SecureRandom.hex(10)}"],
                      'Partner Portal Admin Assigned' => true,
                      'Portal Team' => 'Portal Team',
                      'Partner Portal Admin' => ["rec#{SecureRandom.hex(10)}"],
                      'Name (from Partner Portal Admin)' => ['Users Name'],
                      'Team ID' => 'TeamID',
                      'Ready for Migration' => true,
                      'Assigned Phase' => 'Phase 1',
                      'Partner Agreement (from Applications)' => ["rec#{SecureRandom.hex(10)}"],
                      'Partner Portal Admin Email' => [sample_email] } }
    end

    it 'returns true if the email is an admin' do
      expect(airtable.new_partner_admin_in_airtable?(sample_email, sample_record))
        .to eq(true)
    end

    it 'returns false if the email is not an admin' do
      expect(airtable.new_partner_admin_in_airtable?('not_admin@example.com', sample_record))
        .to eq(false)
    end
  end

  describe '#request_token' do
    let(:code) { SecureRandom.hex(12) }
    let(:redirect_uri) { 'https://example.com' }

    before do
      REDIS_POOL.with { |client| client.flushdb }

      stub_request(:post, 'https://airtable.com/oauth2/v1/token')
        .with(
          body: {
            'code' => code,
            'redirect_uri' => redirect_uri,
            'grant_type' => 'authorization_code',
            'code_verifier' => anything,
          },
          headers: {
            'Content-Type' => 'application/x-www-form-urlencoded',
            'Accept' => '*/*',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'User-Agent' => 'Ruby',
          },
        )
        .to_return(status: 200, body: token_response, headers: {})

      allow(airtable).to receive(:token_basic_authorization_header)
        .and_return({ 'Authorization' => 'Basic mock_auth' })
    end

    it 'requests and saves the token' do
      expect { airtable.request_token(code, redirect_uri) }.to change {
        REDIS_POOL.with do |redis|
          redis.get("#{user_uuid}.airtable_oauth_token")
        end
      }.from(nil).to('mock_access_token')
    end
  end

  describe '#needs_refreshed_token?' do
    let(:user_uuid) { 'test-user-uuid' }
    let(:airtable) { Airtable.new(user_uuid) }

    before do
      REDIS_POOL.with do |redis|
        redis.setex("#{user_uuid}.airtable_oauth_token", 6000.seconds, 'token')
      end
    end

    context 'when the token has expired' do
      before do
        REDIS_POOL.with do |redis|
          redis.setex("#{user_uuid}.airtable_oauth_token", 1.seconds, 'token')
          sleep(2) # pause for 2 seconds to let the token expire
        end
      end

      it 'returns true' do
        expect(airtable.needs_refreshed_token?).to eq(true)
      end
    end

    context 'when the token has not expired' do
      it 'returns false' do
        expect(airtable.needs_refreshed_token?).to eq(false)
      end
    end
  end

  describe '#refresh_token' do
    let(:token_response) do
      {
        'access_token' => 'mock_access_token',
        'expires_in' => 3600,
        'refresh_token' => 'mock_refresh_token',
        'refresh_expires_in' => 7200,
      }.to_json
    end

    before do
      REDIS_POOL.with do |redis|
        redis.setex("#{user_uuid}.airtable_oauth_refresh_token",
                     6000.seconds,
                     'refresh_token')
        redis.setex("#{user_uuid}.airtable_oauth_token",
                     60 * 60 * 24 * 60.seconds,
                     'old_access_token')
      end

      stub_request(:post, 'https://airtable.com/oauth2/v1/token').
        with(
          body: { 'grant_type' => 'refresh_token',
                 'redirect_uri' => 'https://example.com',
                 'refresh_token' => 'refresh_token' },
          headers: {
            'Accept' => '*/*',
         'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
         'Authorization' => 'Basic mock_auth',
         'Content-Type' => 'application/x-www-form-urlencoded',
         'User-Agent' => 'Ruby',
          },
        ).
        to_return(status: 200, body: token_response, headers: {})

      allow(airtable).to receive(:token_basic_authorization_header)
        .and_return({ 'Authorization' => 'Basic mock_auth' })

      allow(airtable).to receive(:save_token).and_call_original
    end

    it 'refreshes the token and calls save_token' do
      airtable.refresh_token('https://example.com')
      expect(airtable).to have_received(:save_token)
    end
  end

  describe '#has_token?' do
    context 'there is a token' do
      it 'checks if a token exists' do
        REDIS_POOL.with do |redis|
          redis.setex("#{user_uuid}.airtable_oauth_token", 6000.seconds, 'token')
        end
        expect(airtable.has_token?).to eq(true)
      end
    end

    context 'there is not a token' do
      it 'checks if a token exists' do
        REDIS_POOL.with do |redis|
          redis.setex("#{user_uuid}.airtable_oauth_token", 1.seconds, 'token')
          sleep(2)
        end
        expect(airtable.has_token?).to eq(false)
      end
    end
  end

  describe '#generate_oauth_url' do
    it 'generates an oauth url' do
      base_url = 'http://localhost:3001'
      oauth_url = airtable.generate_oauth_url(base_url)
      expect(oauth_url).to include('authorize')
      expect(oauth_url).to include('client_id=')
      expect(oauth_url).to include('redirect_uri=')
    end
  end

  describe '#build_redirect_uri' do
    it 'generates the correct redirect URI' do
      request = double('Request')
      allow(request).to receive(:protocol).and_return('http://')
      allow(request).to receive(:host_with_port).and_return('localhost:3000')

      expected_uri = 'http://localhost:3000/airtable/oauth/redirect'
      redirect_uri = airtable.build_redirect_uri(request)

      expect(redirect_uri).to eq(expected_uri)
    end
  end
end
