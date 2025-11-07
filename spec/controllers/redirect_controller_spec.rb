require 'rails_helper'

RSpec.describe RedirectController do
  before do
    sign_in create(:user)
  end

  it 'can redirect a documentation link to the right URL' do
    get :show, params: { destination: '/' }
    expect(response).to have_http_status(:moved_permanently)
    expect(response).to redirect_to('https://developers.login.gov/')
  end

  it 'can redirect with extra path segments' do
    get :show, params: { destination: '/some/path?with=params' }
    expect(response).to have_http_status(:moved_permanently)
    expect(response).to redirect_to('https://developers.login.gov/some/path?with=params')
  end
end
