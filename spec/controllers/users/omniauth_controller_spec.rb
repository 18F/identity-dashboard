require 'rails_helper'

describe Users::OmniauthController do
  include Devise::Test::ControllerHelpers

  describe '#callback' do
    let(:uuid) { '123-asdf-qwerty' }
    let(:email) { 'test@test.com' }
    let(:omniauth_hash) do
      {
        'info' => {
          'email' => email,
          'uuid' => uuid,
        },
      }
    end

    before do
      subject.request.env['omniauth.auth'] = omniauth_hash
    end

    context 'when a user exists with the given email' do
      it 'signs the user in' do
        user = create(:user, email: email)

        expect(subject).to receive(:sign_in).with(user)

        get :callback

        expect(user.reload.uuid).to eq(uuid)
        expect(response).to redirect_to(root_url)
      end

      it 'updates the UUID to match Login.gov' do
        user = create(:user, email: email, uuid: 'asdf')

        get :callback

        expect(user.reload.uuid).to eq(uuid)
        expect(response).to redirect_to(root_url)
      end
    end

    context 'when a user does not exist with the given email' do
      it 'redirects to the empty user path' do
        user = create(:user, email: 'not-the-email@test.com')

        expect(subject).to_not receive(:sign_in)

        get :callback

        expect(user.reload.uuid).to be_nil
        expect(response).to redirect_to(users_none_url)
      end
    end
  end
end
