require 'rails_helper'

RSpec.describe Salesforce do
  let(:salesforce) { Salesforce.new }
  let(:instance_url) { 'https://localhost:1234' }
  let(:consumer_key) { 'fake_consumer_key' }
  let(:consumer_secret) { 'fake_consumer_secret' }

  before do
    Rails.cache.delete(Salesforce::TOKEN_CACHE_KEY)
    allow(IdentityConfig.store).to receive(:salesforce_instance_url).and_return(instance_url)
    allow(IdentityConfig.store).to receive(:salesforce_consumer_key).and_return(consumer_key)
    allow(IdentityConfig.store).to receive(:salesforce_consumer_secret).and_return(consumer_secret)
  end

  describe '#token' do
    it 'fetches and caches an access token' do
      stub_request(:post, "#{instance_url}/services/oauth2/token")
        .with(body: hash_including(
          'grant_type' => 'client_credentials',
          'client_id' => consumer_key,
          'client_secret' => consumer_secret,
        ))
        .to_return(
          status: 200,
          body: { access_token: 'mock_access_token' }.to_json,
          headers: {},
        )

      expect(salesforce.token).to eq('mock_access_token')
      # cached, so a second call does not hit the network again
      expect(salesforce.token).to eq('mock_access_token')
    end

    it 'raises when Salesforce rejects the credentials' do
      stub_request(:post, "#{instance_url}/services/oauth2/token")
        .to_return(
          status: 400,
          body: {
            error: 'invalid_client_id',
            error_description: 'client identifier invalid',
          }.to_json,
          headers: {},
        )

      expect { salesforce.token }.to raise_error(a_string_including('invalid_client_id'))
    end
  end

  describe '#application_contacts_for_team_uuids' do
    before { Rails.cache.write(Salesforce::TOKEN_CACHE_KEY, 'mock_access_token') }

    it 'returns [] without a request when there are no uuids' do
      expect(salesforce.application_contacts_for_team_uuids([])).to eq([])
    end

    it 'queries by the given team uuids and returns the records' do
      records = [{ 'Name' => 'LDGAC-1', 'LDGCRM_P3_Team_UUID__c' => 'uuid-1' }]

      stub_request(:get, "#{instance_url}/services/data/#{Salesforce::API_VERSION}/query")
        .with(
          query: hash_including(
            'q' => a_string_including("WHERE LDGCRM_P3_Team_UUID__c IN ('uuid-1', 'uuid-2')"),
          ),
          headers: { 'Authorization' => 'Bearer mock_access_token' },
        )
        .to_return(status: 200, body: { records: records }.to_json, headers: {})

      result = salesforce.application_contacts_for_team_uuids(%w[uuid-1 uuid-2])

      expect(result).to eq(records)
    end

    it 'raises when Salesforce returns an error array' do
      stub_request(:get, "#{instance_url}/services/data/#{Salesforce::API_VERSION}/query")
        .with(query: hash_including('q' => anything))
        .to_return(
          status: 400,
          body: [{ 'message' => 'No such column', 'errorCode' => 'INVALID_FIELD' }].to_json,
          headers: {},
        )

      expect { salesforce.application_contacts_for_team_uuids(%w[uuid-1]) }
        .to raise_error(a_string_including('No such column'))
    end

    it 'escapes a quote in a uuid before building the SOQL' do
      stub_request(:get, "#{instance_url}/services/data/#{Salesforce::API_VERSION}/query")
        .with(
          query: hash_including(
            'q' => a_string_including("IN ('o\\'brien')"),
          ),
        )
        .to_return(status: 200, body: { records: [] }.to_json, headers: {})

      salesforce.application_contacts_for_team_uuids(["o'brien"])
    end
  end
end
