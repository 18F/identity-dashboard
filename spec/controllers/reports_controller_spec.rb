require 'rails_helper'

RSpec.describe ReportsController do
  let(:logingov_admin) { create(:user, :logingov_admin) }

  it 'can get' do
    sign_in logingov_admin
    get :index
    expect(response).to have_http_status(:ok)
  end
end