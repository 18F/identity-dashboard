require 'rails_helper'

xdescribe 'SSO' do
  it 'uses external SAML IdP' do
    expect(User.count).to eq 0

    get '/users/auth/saml'
    expect(response).to redirect_to(/#{Figaro.env.saml_idp_sso_url}/)

    idp_uri = URI(response.headers['Location'])
    saml_idp_resp = Net::HTTP.get(idp_uri)

    resp_xml = Base64.decode64(saml_idp_resp)

    expect(resp_xml).to match(
      /<NameID Format="urn:oasis:names:tc:SAML:2.0:nameid-format:persistent">/,
    )

    post '/users/auth/saml/callback', SAMLResponse: saml_idp_resp

    expect(response).to redirect_to('http://www.example.com/')
    expect(User.count).to eq 1
  end
end
