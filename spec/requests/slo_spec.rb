require 'rails_helper'

describe 'SLO' do
  it 'uses external SAML IdP' do
    # ask the IdP to initiate a SLO
    idp_uri = URI(ENV['IDP_SLO_URL'])
    saml_idp_resp = Net::HTTP.get(idp_uri)

    # send the SAMLRequest to our logout endpoint
    post '/users/auth/saml/logout', SAMLRequest: saml_idp_resp, RelayState: 'the_idp_session_id'

    # redirect to complete the sign-out at the IdP
    expect(response).to redirect_to(%r{idp.example.com/saml/logout})
  end
end
