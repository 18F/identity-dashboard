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
      Rails.cache.write("#{user_uuid}.airtable_oauth_token", user_token)

      response_body = {
        'records' => [
          { 'fields' => { 'Issuer String' => 'Issuer 1' } },
          { 'fields' => { 'Issuer String' => 'Issuer 3' } },
        ],
        'offset' => nil,
      }.to_json

      # Include the missing headers in the request stub
      stub_request(:get, "https://api.airtable.com/v0/#{Airtable::APP_ID}/#{Airtable::TABLE_ID}?offset=")
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

  describe '#get_admin_emails_for_record' do
    before do
      allow(airtable).to receive(:token_bearer_authorization_header).and_return({})
      allow(airtable).to receive(:get_admin_emails_for_record).with(sample_record).and_return([sample_email.downcase])
    end

    it 'returns admin emails for a given record' do
      expect(airtable.get_admin_emails_for_record(sample_record)).to include(sample_email.downcase)
    end
  end

  describe '#isNewPartnerAdminInAirtable?' do
    before do
      allow(airtable).to receive(:get_admin_emails_for_record).with(sample_record).and_return([sample_email.downcase])
    end

    it 'returns true if the email is an admin' do
      expect(airtable.isNewPartnerAdminInAirtable?(sample_email, sample_record)).to eq(true)
    end

    it 'returns false if the email is not an admin' do
      expect(airtable.isNewPartnerAdminInAirtable?('not_admin@example.com',
sample_record)).to eq(false)
    end
  end

  describe '#request_token' do
    let(:code) { SecureRandom.hex(12) }

    before do
      Rails.cache.clear

      stub_request(:post, 'https://airtable.com/oauth2/v1/token')
        .with(
          body: {
            'code' => code,
            'redirect_uri' => Airtable::REDIRECT_URI,
            'grant_type' => 'authorization_code',
            'code_verifier' => anything, # Stubbing since it's generated and unique each time
          },
          headers: {
            'Content-Type' => 'application/x-www-form-urlencoded',
            'Accept' => '*/*',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'User-Agent' => 'Ruby',
          },
        )
        .to_return(status: 200, body: token_response, headers: {})

      allow(airtable).to receive(:token_basic_authorization_header).and_return({ 'Authorization' => 'Basic mock_auth' })
    end

    it 'requests and saves the token' do
      expect { airtable.request_token(code) }.to change {
        Rails.cache.read("#{user_uuid}.airtable_oauth_token")
      }.from(nil).to('mock_access_token')
    end
  end

  describe '#needs_refreshed_token?' do
    let(:user_uuid) { 'test-user-uuid' }
    let(:airtable) { Airtable.new(user_uuid) }

    before do
      allow(Rails.cache).to receive(:read).with("#{user_uuid}.airtable_oauth_token_expiration").and_return(expiration_time)
    end

    context 'when the token has expired' do
      let(:expiration_time) { DateTime.now - 1 } # Expired time in the past

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
      allow(Rails.cache).to receive(:read).with("#{user_uuid}.airtable_oauth_refresh_token").and_return('refresh_token')
      allow(Rails.cache).to receive(:read).with("#{user_uuid}.airtable_oauth_token").and_return('old_access_token')

      stub_request(:post, 'https://airtable.com/oauth2/v1/token')
        .with(
          body: {
            'refresh_token' => 'refresh_token',
            'grant_type' => 'refresh_token',
            'redirect_uri' => Airtable::REDIRECT_URI,
          },
          headers: {
            'Content-Type' => 'application/x-www-form-urlencoded',
            'Accept' => '*/*',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'User-Agent' => 'Ruby',
          },
        )
        .to_return(status: 200, body: token_response, headers: {})

      allow(airtable).to receive(:token_basic_authorization_header).and_return({ 'Authorization' => 'Basic mock_auth' })

      allow(airtable).to receive(:save_token).and_call_original
    end

    it 'refreshes the token and calls save_token' do
      airtable.refresh_token
      expect(airtable).to have_received(:save_token)
    end
  end

  describe '#has_token?' do
    it 'checks if a token exists' do
      allow(Rails.cache).to receive(:read).with("#{user_uuid}.airtable_oauth_token").and_return('token')
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
end
