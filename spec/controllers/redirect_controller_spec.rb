require 'rails_helper'

RSpec.describe RedirectController do
  before do
    sign_in create(:user)
  end

  it 'can redirect without extra path segments' do
    get :show, params: { destination: '/' }
    expect(response).to have_http_status(:moved_permanently)
    expect(response).to redirect_to('https://developers.login.gov/')
  end

  it 'can redirect with extra path segments' do
    get :show, params: { destination: '/some/path#fragment' }
    expect(response).to have_http_status(:moved_permanently)
    expect(response).to redirect_to('https://developers.login.gov/some/path#fragment')
  end

  it 'sanitizes unsafe characters from destination' do
    unsafe_url = '/path!@$%^&*()+=[]\;,{}|":<>?`~#_-/section'
    get :show, params: { destination: unsafe_url }

    expect(response).to have_http_status(:moved_permanently)
    expect(response).to redirect_to('https://developers.login.gov/path#_-/section')
  end

  context 'logging' do
    let(:logger_double) { instance_double(EventLogger) }

    before do
      allow(logger_double).to receive(:redirect)
      allow(EventLogger).to receive(:new).and_return(logger_double)
    end

    it 'logs the redirect event' do
      request.env['HTTP_REFERER'] = 'https://old.url'
      get :show, params: { destination: '/some/path#fragment' }

      expect(logger_double).to have_received(:redirect).with(
        { origin_url: 'https://old.url',
          destination_url: 'https://developers.login.gov/some/path#fragment' },
      )
    end
  end
end
