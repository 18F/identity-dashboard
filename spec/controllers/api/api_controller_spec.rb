require 'rails_helper'

RSpec.describe Api::ApiController do
  let(:token) do
    token = AuthToken.new_for_user(user)
    token.save!
    token.ephemeral_token
  end

  def add_token_to_headers(controller, user, token)
    auth_header_value = ActionController::HttpAuthentication::Token.encode_credentials(
      token, email: user.email
    )
    request.headers['HTTP_AUTHORIZATION'] = auth_header_value
  end

  controller(Api::ApiController) do
    def index
      render plain: 'Test'
    end
  end


  context 'when user is Login.gov Admin' do
    let(:user) { create(:user, :logingov_admin) }

    it 'forbids access without a token' do
      # TODO: this test should pass before ATO
      pending
      expect(request.headers['HTTP_AUTHORIZATION']).to be_blank
      get :index
      expect(response).to be_unauthorized
      expect(response.body).to include('Access denied')
    end

    it 'can get with token' do
      add_token_to_headers(controller, user, token)
      get :index
      expect(response).to be_ok
      expect(response.body).to_not include('Access denied')
    end
  end

  context 'when user with token is not Login.gov Admin' do
    let(:user) { create(:user) }

    before { add_token_to_headers(controller, user, token) }

    it 'cannot get' do
      get :index
      expect(response).to be_unauthorized
      expect(response.body).to include('Access denied')
    end
  end
end
