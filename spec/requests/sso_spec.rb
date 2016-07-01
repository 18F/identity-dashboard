require 'rails_helper'

describe 'SSO' do
  it 'uses external SAML IdP' do
    expect(User.count).to eq 0

    get '/users/auth/saml'
    expect(response).to redirect_to(/#{ENV['IDP_SSO_URL']}/)

    idp_uri = URI(response.headers['Location'])
    saml_idp_resp = Net::HTTP.get(idp_uri)

    post '/users/auth/saml/callback', SAMLResponse: saml_idp_resp

    expect(response).to redirect_to('http://www.example.com/')
    expect(User.count).to eq 1
  end
end
