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

end
