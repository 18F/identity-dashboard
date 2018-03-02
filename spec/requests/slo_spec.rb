require 'rails_helper'

xdescribe 'SLO' do
  describe 'IdP-initiated' do
    it 'uses external SAML IdP' do
      # ask the IdP to initiate a SLO
      idp_uri = URI(Figaro.env.saml_idp_slo_url)
      saml_idp_resp = Net::HTTP.get(idp_uri)

      # send the SAMLRequest to our logout endpoint
      post '/users/auth/saml/logout', SAMLRequest: saml_idp_resp, RelayState: 'the_idp_session_id'

      # redirect to complete the sign-out at the IdP
      expect(response).to redirect_to(%r{idp.example.com/saml/logout})

      idp_logout_uri = URI(response.headers['Location'])
      idp_logout_params = CGI.parse(idp_logout_uri.query)

      expect(idp_logout_params[:Signature]).to_not be_nil
    end

    it 'renders failure correctly' do
      idp_uri = URI(Figaro.env.saml_idp_slo_url)
      saml_idp_resp = Net::HTTP.get(idp_uri)

      # mangle the SAML payload a little to trigger error
      saml_idp_resp += 'foo'

      post '/users/auth/saml/logout', SAMLRequest: saml_idp_resp, RelayState: 'the_idp_session_id'

      expect(response.body).to match(/was not valid/)
    end
  end

  describe 'SP-initiated' do
    it 'uses external SAML IdP' do
      user = create(:user)
      login_as(user)

      # ask the SP to initiate a SLO
      get '/users/logout'

      expect(response).to redirect_to(%r{idp.example.com/saml/logout})

      # send the SAMLRequest to IdP
      idp_uri = URI(response.headers['Location'])

      idp_logout_params = CGI.parse(idp_uri.query)
      expect(idp_logout_params[:Signature]).to_not be_nil

      saml_idp_resp = Net::HTTP.get(idp_uri)

      # send the SAMLResponse back to our SP
      post '/users/auth/saml/logout', SAMLResponse: saml_idp_resp

      # expect we are logged out, on our site
      expect(response).to redirect_to(root_url)
      expect(flash[:notice]).to eq I18n.t('omniauth.logout_ok')
    end

    it 'renders failure correctly' do
      user = create(:user)
      login_as(user)

      get '/users/logout'
      idp_uri = URI(response.headers['Location'])
      saml_idp_resp = Net::HTTP.get(idp_uri)

      saml_idp_resp += 'foo'

      post '/users/auth/saml/logout', SAMLResponse: saml_idp_resp

      expect(response.body).to match(I18n.t('omniauth.logout_fail'))
    end
  end
end
