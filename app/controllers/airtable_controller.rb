class AirtableController < AuthenticatedController
  def index
    Rails.cache.fetch("#{current_user.uuid}.airtable_code_verifier", expires_in: 10.minutes) do
      SecureRandom.alphanumeric(50)
    end
    session[:airtable_state] = SecureRandom.uuid

    airtable_api = Airtable.new(current_user.uuid)
    airtable_api.refreshToken if airtable_api.needsRefreshedToken?
  end

  def oauth_redirect
    return unless session[:airtable_state] == params[:state]

    airtable_api = Airtable.new(current_user.uuid)
    airtable_api.requestToken(params[:code])

    redirect_to airtable_path
  end
end
