require 'rails_helper'

RSpec.describe Api::ApiController do
  let(:token) do
    token = AuthToken.new_for_user(user)
    token.save!
    token.ephemeral_token
  end

  def add_token_to_headers(user, token)
    auth_header_value = ActionController::HttpAuthentication::Token.encode_credentials(
      token, email: user.email
    )
    request.headers['HTTP_AUTHORIZATION'] = auth_header_value
  end

  controller(described_class) do
    def index
      render plain: 'Test'
    end
  end

  context 'with API token required enabled' do
    before do
      allow(IdentityConfig.store).to receive(:api_token_required_enabled).and_return(true)
    end

    context 'when user is Login.gov Admin' do
      let(:user) { create(:user, :logingov_admin) }

      it 'forbids access without a token' do
        expect(request.headers['HTTP_AUTHORIZATION']).to be_blank
        get :index
        expect(response).to be_unauthorized
        expect(response.body).to include('Access denied')
      end

      it 'can get with token' do
        add_token_to_headers(user, token)
        get :index
        expect(response).to be_ok
        expect(response.body).to_not include('Access denied')
      end
    end

    context 'when user with token is not Login.gov Admin' do
      let(:user) { create(:user) }

      before { add_token_to_headers(user, token) }

      it 'cannot get' do
        get :index
        expect(response).to be_unauthorized
        expect(response.body).to include('Access denied')
      end
    end
  end

  context 'with API token required disabled' do
    before do
      allow(IdentityConfig.store).to receive(:api_token_required_enabled).and_return(false)
    end

    let(:user) { create(:user, :logingov_admin) }

    it 'allows access without a token' do
      expect(request.headers['HTTP_AUTHORIZATION']).to be_blank
      get :index
      expect(response).to be_ok
      expect(response.body).to_not include('Access denied')
    end

    it 'allows access with a token' do
      add_token_to_headers(user, token)
      get :index
      expect(response).to be_ok
      expect(response.body).to_not include('Access denied')
    end
  end
end
