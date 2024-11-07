# frozen_string_literal: true

class Analytics
  include AnalyticsEvents

  attr_reader :user, :request, :session

  # @param [User] user
  # @param [ActionDispatch::Request,nil] request
  # @param [Hash] session
  # @param [Ahoy::Tracker,nil] ahoy
  def initialize(user:, request:, session:, ahoy: nil)
    @user = user
    @request = request
    @session = session
    @ahoy = ahoy || Ahoy::Tracker.new(request: request)
  end

  def track_event(event, attributes = {})
    attributes.delete(:pii_like_keypaths)
    update_session_events_and_paths_visited_for_analytics(event) if attributes[:success] != false
    analytics_hash = {
      event_properties: attributes.except(:user_id).compact,
      new_event: first_event_this_session?,
      path: request&.path,
      session_duration: session_duration,
      user_id: attributes[:user_id] || user.uuid,
    }

    analytics_hash.merge!(request_attributes) if request
    analytics_hash.merge!(ab_test_attributes(event))

    ahoy.track(event, analytics_hash)
  end

  def update_session_events_and_paths_visited_for_analytics(event)
    session[:events] ||= {}
    session[:first_event] = !@session[:events].key?(event)
    session[:events][event] = true
  end

  def first_event_this_session?
    session[:first_event]
  end

  def request_attributes
    attributes = {
      user_ip: request.remote_ip,
      hostname: request.host,
      pid: Process.pid,
      trace_id: request.headers['X-Amzn-Trace-Id'],
    }

    attributes[:git_sha] = IdentityConfig::GIT_SHA
    if IdentityConfig::GIT_TAG.present?
      attributes[:git_tag] = IdentityConfig::GIT_TAG
    else
      attributes[:git_branch] = IdentityConfig::GIT_BRANCH
    end

    attributes.merge!(browser_attributes)
  end

  def browser
    @browser ||= BrowserCache.parse(request.user_agent)
  end

  def browser_attributes
    {
      user_agent: request.user_agent,
      browser_name: browser.name,
      browser_version: browser.full_version,
      browser_platform_name: browser.platform.name,
      browser_platform_version: browser.platform.version,
      browser_device_name: browser.device.name,
      browser_mobile: browser.device.mobile?,
      browser_bot: browser.bot?,
    }
  end

  def session_duration
    session[:session_started_at].present? ? Time.zone.now - session_started_at : nil
  end

  def session_started_at
    value = session[:session_started_at]
    return value unless value.is_a?(String)
    Time.zone.parse(value)
  end
end
