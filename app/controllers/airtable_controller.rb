class AirtableController < AuthenticatedController
  def index
    code_verifier = Rails.cache.fetch("#{current_user.uuid}.airtable_code_verifier", expires_in: 10.minutes) do
      SecureRandom.alphanumeric(50)
    end
    session[:airtable_state] = SecureRandom.uuid

    airtable_api = Airtable.new(current_user.uuid)
    airtable_api.refreshToken if airtable_api.needsRefreshedToken?
  end

  def issuer_lookup 
    airtable_api = Airtable.new(current_user.uuid)

    record = airtable_api.getMatchingRecords('GSA_LACR_DEV')
    admin_ids = airtable_api.getAdminIds(record)
    admin_emails = airtable_api.getAdminEmails(admin_ids)
    render json: admin_emails
  end

  def oauth_redirect
    return unless session[:airtable_state] == params[:state]

    airtable_api = Airtable.new(current_user.uuid)
    airtable_api.requestToken(params[:code])

    redirect_to airtable_path
  end

  def clear_token
    session.delete(:airtable_token)
    redirect_to airtable_path
  end

end
