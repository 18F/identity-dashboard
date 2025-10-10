class AirtableController < AuthenticatedController
  before_action -> { authorize Airtable }

  def index
    airtable_api = Airtable.new(current_user.uuid)
    airtable_api.refresh_token if airtable_api.needs_refreshed_token?

    base_url = "#{request.protocol}#{request.host_with_port}"
    @oauth_url = airtable_api.generate_oauth_url(base_url)
  end

  def oauth_redirect
    return unless Rails.cache.read("#{current_user.uuid}.airtable_state") == params[:state]

    airtable_api = Airtable.new(current_user.uuid)
    airtable_api.request_token(params[:code])

    redirect_to airtable_path
  end

  def refresh_token
    airtable_api = Airtable.new(current_user.uuid)
    airtable_api.refresh_token

    redirect_to airtable_path
  end

  def clear_token
    Rails.cache.delete("#{current_user.uuid}.airtable_oauth_token")
    Rails.cache.delete("#{current_user.uuid}.airtable_oauth_token_expiration")
    Rails.cache.delete("#{current_user.uuid}.airtable_oauth_refresh_token")
    Rails.cache.delete("#{current_user.uuid}.airtable_oauth_refresh_token_expiration")

    redirect_to airtable_path
  end
end
