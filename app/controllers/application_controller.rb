class ApplicationController < ActionController::Base # :nodoc:
  include Pundit::Authorization

  before_action :set_cache_headers
  before_action :set_paper_trail_whodunnit
  before_action :set_requested_url
  before_action :get_banner_messages

  prepend_before_action :start_session

  protect_from_forgery with: :exception

  rescue_from Pundit::NotAuthorizedError, with: :log_not_auth_and_render_401
  rescue_from ActionController::UnpermittedParameters, with: :log_unperm_params_and_render_401

  def new_session_path(_scope)
    root_url
  end

  def render_401
    # Not specifying the layout can cause problems when the `rescue_from` is triggered
    # from a controller that uses a different layout
    render layout: 'application', file: 'public/401.html', status: :unauthorized
  end

  def log_not_auth_and_render_401(exception)
    log.unauthorized_access_attempt(exception)
    render_401
  end

  def log_unperm_params_and_render_401(exception)
    log.unpermitted_params_attempt(exception)
    render_401
  end

  def user_for_paper_trail
    current_user&.email
  end

  # For lograge
  def append_info_to_payload(payload)
    payload[:user_uuid] = current_user&.uuid
    payload[:user_agent] = request.user_agent
    payload[:ip] = request.remote_ip
    payload[:host] = request.host
    payload[:trace_id] = request.headers['X-Amzn-Trace-Id']
  end

  attr_writer :log

  def log(logger: nil)
    @log ||=
      EventLogger.new(
        user: current_user,
        request: request,
        session: session,
        logger: logger,
      )
  end

  private

  def set_cache_headers
    return if request.path == '/'

    response.headers['Cache-Control'] = 'no-store'
    response.headers['Pragma'] = 'no-cache'
  end

  def set_requested_url
    return if session[:requested_url]

    session[:requested_url] = request.original_url
  end

  def get_banner_messages
    @active_banners = helpers.get_active_banners
  end

  def skip_session_load
    @skip_session_load = true
  end

  def start_session
    return if @skip_session_load

    session[:session_started_at] = Time.zone.now if session[:session_started_at].nil?
  end
end
