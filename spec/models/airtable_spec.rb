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
    let(:user_token) { 'mocked_token' }
    let(:app_id) { IdentityConfig.store.airtable_app_id }
    let(:table_id) { IdentityConfig.store.airtable_table_id }

    before do
      Rails.cache.write("#{user_uuid}.airtable_oauth_token", user_token)
    end

    it 'retrieves matching records' do
      issuers = ['Issuer 1', 'Issuer 2']

      response_body = {
        'records' => [
          { 'fields' => { 'Issuer String' => 'Issuer 1' } },
          { 'fields' => { 'Issuer String' => 'Issuer 3' } },
        ],
        'offset' => nil,
      }.to_json

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

    it 'returns an empty array when no records match' do
      issuers = ['urn:gov:gsa:app:one', 'urn:gov:gsa:app:two']

      response_body = {
        'records' => [
          { 'fields' => { 'Issuer String' => 'urn:gov:gsa:app:other' } },
          { 'fields' => { 'Issuer String' => 'urn:gov:gsa:app:different' } },
        ],
        'offset' => nil,
      }.to_json

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

      expect(records).to eq([])
    end

    it 'handles records with nil Issuer String field gracefully' do
      issuers = ['Issuer 1']

      response_body = {
        'records' => [
          { 'fields' => { 'Issuer String' => 'Issuer 1' } },
          { 'fields' => { 'Other Field' => 'Some value' } },
          { 'fields' => { 'Issuer String' => nil } },
        ],
        'offset' => nil,
      }.to_json

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
      Rails.cache.clear

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
        Rails.cache.read("#{user_uuid}.airtable_oauth_token")
      }.from(nil).to('mock_access_token')
    end
  end

  describe '#needs_refreshed_token?' do
    let(:user_uuid) { 'test-user-uuid' }
    let(:airtable) { Airtable.new(user_uuid) }

    before do
      allow(Rails.cache).to receive(:read).with("#{user_uuid}.airtable_oauth_token_expiration")
        .and_return(expiration_time)
    end

    context 'when the token has expired' do
      let(:expiration_time) { DateTime.now - 1 }

      it 'returns true' do
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
      allow(Rails.cache).to receive(:read).with("#{user_uuid}.airtable_oauth_refresh_token")
        .and_return('refresh_token')
      allow(Rails.cache).to receive(:read).with("#{user_uuid}.airtable_oauth_token")
        .and_return('old_access_token')

      stub_request(:post, 'https://airtable.com/oauth2/v1/token')
        .with(
          body: {
            'refresh_token' => 'refresh_token',
            'grant_type' => 'refresh_token',
            'redirect_uri' => 'https://example.com',
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

      allow(airtable).to receive(:save_token).and_call_original
    end

    it 'refreshes the token and calls save_token' do
      airtable.refresh_token('https://example.com')
      expect(airtable).to have_received(:save_token)
    end
  end

  describe '#has_token?' do
    it 'checks if a token exists' do
      allow(Rails.cache).to receive(:read).with("#{user_uuid}.airtable_oauth_token")
        .and_return('token')
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
end
