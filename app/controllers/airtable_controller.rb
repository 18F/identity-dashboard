# AirtableContoller helps the user manage their Airtable API tokens
class AirtableController < AuthenticatedController
  before_action -> { authorize Airtable }

  def index
    @airtable_api = airtable_api
    if @airtable_api.needs_refreshed_token?
      @airtable_api.refresh_oauth_token(@airtable_api.build_redirect_uri(request))
    end

    base_url = "#{request.protocol}#{request.host_with_port}"
    @oauth_url = @airtable_api.generate_oauth_url(base_url)
  end

  def oauth_redirect
    unless airtable_api.state == params[:state]
      flash[:error] = 'State does not match, blocking token request.'
      redirect_to airtable_path and return
    end

    airtable_api.request_token(params[:code], airtable_api.build_redirect_uri(request))

    redirect_to airtable_path
  end

  def refresh_token
    airtable_api.refresh_oauth_token(airtable_api.build_redirect_uri(request))

    redirect_to airtable_path
  end

  def clear_token
    airtable_api.delete

    redirect_to airtable_path
  end

  private

  def airtable_api
    Airtable.find_by(user: current_user) ||
      Airtable.new(current_user)
  end
end
