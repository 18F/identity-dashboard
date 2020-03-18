require 'rails_helper'

describe ServiceProviderLogosController do
  let(:service_provider) { create(:service_provider) }
  let(:user) { service_provider.user }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    sign_in user
  end

  describe '#show' do
    context 'when the service provider has a logo' do
      it 'renders the logo' do
        logo_path = File.expand_path('../fixtures', __dir__) + '/logo.svg'
        service_provider.logo_file.attach(
          io: File.open(logo_path),
          filename: 'logo.svg',
          content_type: 'image/svg'
        )

        get :show, params: { id: service_provider.id }

        expect(response.status).to eq(200)
        expect(response.content_type).to eq('image/svg+xml')
        expect(response.body).to eq(File.read(logo_path))
      end
    end

    context 'when the service provider does not have a logo' do
      it 'does not render the logo' do
        get :show, params: { id: service_provider.id }

        expect(response.status).to eq(404)
      end
    end
  end
end
