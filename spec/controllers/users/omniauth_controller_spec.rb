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
          'id_token' => 'abc123',
        },
      }
    end

    before do
      subject.request.env['omniauth.auth'] = omniauth_hash
    end

    context 'when a user exists and is on a team or allowed to create teams' do
      it 'signs the user in' do
        user = create(:team_member, email:)
        session[:requested_url] = service_providers_url

        expect(subject).to receive(:sign_in).with(user)

        get :callback

        expect(user.reload.uuid).to eq(uuid)
        expect(response).to redirect_to(service_providers_url)
      end
    end

    context 'when a user is not on a team, but is a login.gov admin' do
      it 'signs the user in' do
        user = create(:user, :logingov_admin, email:)
        session[:requested_url] = service_providers_url

        expect(subject).to receive(:sign_in).with(user)

        get :callback

        expect(user.reload.uuid).to eq(uuid)
        expect(response).to redirect_to(service_providers_url)
      end
    end

    context 'when a user exists but is on no team and not allowed to create teams' do
      it 'redirects to the empty user path' do
        user = create(:user, email:)
        session[:requested_url] = service_providers_url

        expect(subject).not_to receive(:sign_in)

        get :callback

        expect(response).to redirect_to(users_none_url)
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

  describe '#callback (allowed tld)' do
    let(:uuid) { '123-asdf-qwerty' }
    let(:email) { 'test@gsa.gov' }
    let(:omniauth_hash) do
      {
        'info' => {
          'email' => email,
          'uuid' => uuid,
        },
        'credentials' => {
          'id_token' => 'abc123',
        },
      }
    end

    before do
      subject.request.env['omniauth.auth'] = omniauth_hash
    end

    context 'when a user exists but is on no team' do
      it 'signs the user in' do
        user = create(:user, email:)
        session[:requested_url] = service_providers_url

        expect(subject).to receive(:sign_in).with(user)

        get :callback

        expect(user.reload.uuid).to eq(uuid)
        expect(response).to redirect_to(service_providers_url)
      end
    end
  end
end
