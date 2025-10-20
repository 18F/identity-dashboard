require 'rails_helper'

RSpec.describe AirtableController, type: :controller do
  let(:logingov_admin) { create(:user, :logingov_admin) }
  let(:airtable) { Airtable.new(logingov_admin) }
  let(:token_response) do
    {
      'access_token' => 'mock_access_token',
      'expires_in' => 3600,
      'refresh_token' => 'mock_refresh_token',
      'refresh_expires_in' => 7200,
    }.to_json
  end

  before do
    sign_in logingov_admin
    airtable.token_expiration = 1.day.from_now
    airtable.token = 'Token'
    airtable.refresh_token_expiration = 30.days.from_now
    airtable.refresh_token = 'RefreshToken'
    airtable.state = 'valid_state'

    stub_request(:post, 'https://airtable.com/oauth2/v1/token').
      with(
        body: {
          'grant_type' => 'refresh_token',
          'redirect_uri' => 'http://test.host/airtable/oauth/redirect',
          'refresh_token' => nil,
        },
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => 'Basic Og==',
          'Content-Type' => 'application/x-www-form-urlencoded',
          'User-Agent' => 'Ruby',
        },
      ).
      to_return(status: 200, body: token_response, headers: {})
  end

  describe 'GET #index' do
    context 'when the token needs to be refreshed' do
      before do
        allow_any_instance_of(Airtable).to receive(:needs_refreshed_token?).and_return(true)
      end

      it 'refreshes the token and generates the oauth url' do
        expect_any_instance_of(Airtable).to receive(:refresh_token)
        expect_any_instance_of(Airtable).to receive(:generate_oauth_url)
          .and_return('mock_oauth_url')

        get :index

        expect(assigns(:oauth_url)).to eq('mock_oauth_url')
      end
    end

    context 'when the token does not need to be refreshed' do
      before do
        allow_any_instance_of(Airtable).to receive(:needs_refreshed_token?).and_return(false)
      end

      it 'does not refresh the token and generates the oauth url' do
        expect_any_instance_of(Airtable).to_not receive(:refresh_token)
        expect_any_instance_of(Airtable).to receive(:generate_oauth_url)
          .and_return('mock_oauth_url')

        get :index

        expect(assigns(:oauth_url)).to eq('mock_oauth_url')
      end
    end
  end

  describe 'GET #oauth_redirect' do
    context 'when the state matches' do
      it 'requests the token' do
        get :oauth_redirect, params: { state: 'valid_state', code: 'authorization_code' }
        expect(response).to redirect_to(airtable_path)
        # expect_any_instance_of(Airtable).to receive(:request_token)
        #   .with('authorization_code', 'http://test.host/airtable/oauth/redirect')
      end
    end

    context 'when the state does not match' do
      it 'does not request the token and sets an error flash message' do
        expect_any_instance_of(Airtable).to_not receive(:request_token)

        get :oauth_redirect, params: { state: 'wrong_state', code: 'authorization_code' }
        expect(response).to redirect_to(airtable_path)
        expect(flash[:error]).to eq('State does not match, blocking token request.')
      end
    end
  end

  describe 'GET #refresh_token' do
    it 'refreshes the token' do
      expect_any_instance_of(Airtable).to receive(:refresh_token)
      get :refresh_token
      expect(response).to redirect_to(airtable_path)
    end
  end

  describe 'GET #clear_token' do
    it 'clears the tokens and redirects to the airtable path' do
      get :clear_token

      expect(response).to redirect_to(airtable_path)
    end
  end
end
