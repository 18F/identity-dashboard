require 'rails_helper'

RSpec.describe Airtable, type: :model do
  let(:user_uuid) { 'test-user-uuid' }
  let(:user) { create(:user) }
  let(:airtable) { Airtable.new(user) }
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

  before do
    airtable.token_expiration = 1.day.from_now
    airtable.token = 'Token'
    airtable.refresh_token_expiration = 30.days.from_now
    airtable.refresh_token = 'RefreshToken'
  end

  describe '#get_matching_records' do
    it 'retrieves matching records' do
      issuers = ['Issuer 1', 'Issuer 2']
      user_token = 'mocked_token'
      airtable.token = user_token

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

      stub_request(:get, "https://api.airtable.com/v0/#{app_id}/#{table_id}?offset=")
        .with(headers: {
          'Authorization' => "Bearer #{user_token}",
          'Content-Type' => 'application/x-www-form-urlencoded',
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent' => 'Ruby',
        })
        .to_return(status: 200, body: response_body, headers: {})

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
      airtable.token = nil
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
        airtable.token
      }.from(nil).to('mock_access_token')
    end
  end

  describe '#needs_refreshed_token?' do
    before do
      allow(Rails.cache).to receive(:read).with("#{user_uuid}.airtable_oauth_token_expiration")
        .and_return(expiration_time)
    end

    context 'when the token has expired' do
      let(:expiration_time) { DateTime.now - 1 }

      it 'returns true' do
        airtable.token_expiration = expiration_time
        expect(airtable.needs_refreshed_token?).to eq(true)
      end
    end

    context 'when the token has not expired' do
      let(:expiration_time) { DateTime.now + 1 }

      it 'returns false' do
        expect(airtable.needs_refreshed_token?).to eq(false)
      end
    end

    context 'when the expiration time is not present' do
      let(:expiration_time) { nil }

      it 'returns false' do
        expect(airtable.needs_refreshed_token?).to eq(false)
      end
    end
  end

  describe '#refresh_oauth_token' do
    before do
      # Stub the POST request to Airtable
      stub_request(:post, 'https://airtable.com/oauth2/v1/token')
        .with(
          body: {
            'refresh_token' => 'refresh_token',
            'grant_type' => 'refresh_token',
            'redirect_uri' => 'https://example.com',
          },
          headers: {
            'Content-Type' => 'application/x-www-form-urlencoded',
            'Authorization' => 'Basic mock_auth',
          },
        )
        .to_return(status: 200, body: token_response, headers: {})

      # Mock the method that provides headers
      allow(airtable).to receive(:token_basic_authorization_header)
        .and_return({ 'Authorization' => 'Basic mock_auth' })

      # Assuming refresh_token is initialized
      airtable.refresh_token = 'refresh_token'
    end

    it 'refreshes the token and calls save_token' do
      expect(airtable.token).to eq('Token')
      airtable.refresh_oauth_token('https://example.com')
      expect(airtable.token).to eq('mock_access_token')
    end
  end

  describe '#has_token?' do
    it 'checks if a token exists' do
      expect(airtable.has_token?).to eq(true)
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

  describe '#generate_state' do
    it 'generates a valid UUID' do
      state = airtable.generate_state
      uuid_regex = /\A[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
      expect(state).to match(uuid_regex) # Use a regex to validate the UUID format
    end
  end

  describe '#generate_code_verifier' do
    it 'generates a valid code verifier' do
      code_verifier = airtable.generate_code_verifier

      expect(code_verifier.length).to eq(100) # Check that the length is 100 characters
      expect(code_verifier).to match(/[a-f0-9]+/) # Ensure it contains only hexadecimal characters
    end
  end

  describe '#prepare_api' do
    it 'sets the state and code_verifier, then saves the instance' do
      allow(SecureRandom).to receive(:uuid).and_return('test-uuid-1234')
      allow(SecureRandom).to receive(:hex).with(50).and_return('test-code-verifier-1234567890abcde')

      airtable.prepare_api

      expect(airtable.state).to eq('test-uuid-1234')
      expect(airtable.code_verifier).to eq('test-code-verifier-1234567890abcde')
      expect(airtable).to be_persisted # Check that Airtable instance has been saved
    end
  end
end
