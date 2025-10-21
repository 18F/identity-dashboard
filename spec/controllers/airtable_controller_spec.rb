require 'rails_helper'

RSpec.describe AirtableController, type: :controller do
  let(:logingov_admin) { create(:user, :logingov_admin) }

  before do
    sign_in logingov_admin
  end

  describe 'GET #index' do
    let(:airtable_api) { Airtable.new(logingov_admin.uuid) }

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
    let(:airtable_api) { Airtable.new(logingov_admin.uuid) }

    context 'when the state matches' do
      before do
        REDIS_POOL.with do |redis|
          redis.set("#{logingov_admin.uuid}.airtable_state", 'valid_state')
        end
        # allow(Rails.cache).to receive(:read).with("#{logingov_admin.uuid}.airtable_state")
        #   .and_return('valid_state')
      end

      it 'requests the token' do
        expect_any_instance_of(Airtable).to receive(:request_token)
          .with('authorization_code', 'http://test.host/airtable/oauth/redirect')

        get :oauth_redirect, params: { state: 'valid_state', code: 'authorization_code' }
        expect(response).to redirect_to(airtable_path)
      end
    end

    context 'when the state does not match' do
      before do
        allow(Rails.cache).to receive(:read).with("#{logingov_admin.uuid}.airtable_state")
          .and_return('invalid_state')
      end

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
    before do
      REDIS_POOL.with do |redis|
        redis.set("#{logingov_admin.uuid}_airtable_oauth_token", 'token')
        redis.set("#{logingov_admin.uuid}_airtable_oauth_refresh_token", 'refresh')
      end
    end

    it 'clears the appropriate tokens' do
      REDIS_POOL.with do |redis|
        expect(redis.exists?("#{logingov_admin.uuid}_airtable_oauth_token")).to be_truthy
        expect(redis.exists?("#{logingov_admin.uuid}_airtable_oauth_refresh_token")).to be_truthy
      end

      get :clear_token # Call the action to clear the token

      REDIS_POOL.with do |redis|
        expect(redis.exists?("#{logingov_admin.uuid}_airtable_oauth_token")).to be_falsey
        expect(redis.exists?("#{logingov_admin.uuid}_airtable_oauth_refresh_token")).to be_falsey
      end
      # After the action, these keys should be deleted
      # expect(Rails.cache).to receive(:delete)
      #   .with("#{logingov_admin.uuid}.airtable_oauth_token")
      # expect(Rails.cache).to receive(:delete)
      #   .with("#{logingov_admin.uuid}.airtable_oauth_token_expiration")
      # expect(Rails.cache).to receive(:delete)
      #   .with("#{logingov_admin.uuid}.airtable_oauth_refresh_token")
      # expect(Rails.cache).to receive(:delete)
      #   .with("#{logingov_admin.uuid}.airtable_oauth_refresh_token_expiration")

      # get :clear_token
      # expect(response).to redirect_to(airtable_path)
    end
  end
end
