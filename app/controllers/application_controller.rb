class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :set_paper_trail_whodunnit
  before_action :set_requested_url
  before_action :get_banner_messages

  protect_from_forgery with: :exception

  rescue_from Pundit::NotAuthorizedError, with: :render_401

  def new_session_path(_scope)
    root_url
  end

  def render_401
    render file: 'public/401.html', status: :unauthorized
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

  attr_writer :analytics

  def analytics
    return @analytics if @analytics
    @analytics =
      Analytics.new(
        user: analytics.user,
        request: request,
        session: session,
        ahoy: ahoy,
      )
  end

  def analytics_user
    current_user || AnonymousUser.new
  end

  def sign_out(*args)
    request.cookie_jar.delete('ahoy_visit')
    super
  end

  private

  def set_requested_url
    return if session[:requested_url]
    session[:requested_url] = request.original_url
  end

  def get_banner_messages
    @active_banners = helpers.get_active_banners
  end
end
