# AirtableContoller helps the user manage their Airtable API tokens
class AirtableController < AuthenticatedController
  before_action -> { authorize Airtable }

  def index
    if airtable_api.needs_refreshed_token?
      airtable_api.refresh_token(airtable_api.build_redirect_uri(request))
    end

    @token, @token_expiration = REDIS_POOL.with do |redis|
      [redis.get("#{current_user.uuid}.airtable_oauth_token"),
       DateTime.now + redis.TTL("#{current_user.uuid}.airtable_oauth_token").seconds]
    end

    return unless @token.blank?

    base_url = "#{request.protocol}#{request.host_with_port}"
    @oauth_url = airtable_api.generate_oauth_url(base_url)
  end

  def oauth_redirect
    cached_state = REDIS_POOL.with do |redis|
      redis.get("#{current_user.uuid}.airtable_state")
    end

    unless cached_state == params[:state]
      flash[:error] = 'State does not match, blocking token request.'
      redirect_to airtable_path and return
    end

    airtable_api.request_token(params[:code], airtable_api.build_redirect_uri(request))

    redirect_to airtable_path
  end

  def refresh_token
    airtable_api.refresh_token(airtable_api.build_redirect_uri(request))

    redirect_to airtable_path
  end

  def clear_token
    REDIS_POOL.with do |redis|
      prefix = "#{current_user.uuid}*"

      keys_to_delete = []
      redis.scan_each(match: prefix) do |key|
        keys_to_delete << key
      end

      keys_to_delete.each_slice(10) do |batch|
        redis.del(batch)
      end
    end

    redirect_to airtable_path
  end

  private

  def airtable_api
    Airtable.new(current_user.uuid)
  end
end
