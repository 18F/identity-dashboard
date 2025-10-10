class AirtableController < AuthenticatedController
  def index
    code_verifier = Rails.cache.fetch("#{current_user.uuid}.airtable_code_verifier",
expires_in: 10.minutes) do
      SecureRandom.alphanumeric(50)
    end
    session[:airtable_state] = SecureRandom.uuid
    @code_challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier)).delete('=')

    base_url = "#{request.protocol}#{request.host_with_port}"
    @redirect_uri = "#{base_url}/airtable/oauth/redirect&scope=data.records:read&state"
    airtable_api = Airtable.new(current_user.uuid)
    airtable_api.refreshToken if airtable_api.needsRefreshedToken?
  end

  def oauth_redirect
    return unless session[:airtable_state] == params[:state]

    airtable_api = Airtable.new(current_user.uuid)
    airtable_api.requestToken(params[:code])

    redirect_to airtable_path
  end

  def refresh_token
    airtable_api = Airtable.new(current_user.uuid)
    airtable_api.refreshToken

    redirect_to airtable_path
  end

  def reset_token
    Rails.cache.delete("#{current_user.uuid}.airtable_oauth_token")
    Rails.cache.delete("#{current_user.uuid}.airtable_oauth_token_expiration")
    Rails.cache.delete("#{current_user.uuid}.airtable_oauth_refresh_token")
    Rails.cache.delete("#{current_user.uuid}.airtable_oauth_refresh_token_expiration")

    redirect_to airtable_path
  end
end
