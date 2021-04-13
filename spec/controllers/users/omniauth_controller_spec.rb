require 'rails_helper'

describe Users::OmniauthController do
  describe '#callback' do
    let(:uuid) { '123-asdf-qwerty' }
    let(:email) { 'test@test.com' }
    let(:omniauth_hash) do
      {
        'info' => {
          'email' => email,
          'uuid' => uuid,
        },
        'credentials' => {
          'id_token'=> 'abc123',
        },
      }
    end

    before do
      subject.request.env['omniauth.auth'] = omniauth_hash
    end

    context 'when a user exists' do
      it 'signs the user in' do
        user = create(:user, email: email)
        session[:requested_url] = service_providers_url

        expect(subject).to receive(:sign_in).with(user)

        get :callback

        expect(user.reload.uuid).to eq(uuid)
        expect(response).to redirect_to(service_providers_url)
      end
    end

    context 'when a user does not exist' do
      let(:email) { 'test@test.agency․gov' }

      it 'redirects to the empty user path' do
        expect(subject).not_to receive(:sign_in)

        get :callback

        expect(response).to redirect_to(users_none_url)
      end
    end
  end
end
