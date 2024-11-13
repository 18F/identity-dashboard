# frozen_string_literal: true

class Analytics
  include AnalyticsEvents

  attr_reader :user, :request, :session

  # @param [User] user
  # @param [ActionDispatch::Request,nil] request
  # @param [Hash] session
  # @param [LGLogger,nil] logger
  def initialize(user:, request:, session:, logger: nil)
    puts 'Analytics initialized'
    @user = user
    @request = request
    @session = session
    @lg_logger = logger || create_lg_logger
  end

  def track_event(event, attributes = {})
    analytics_hash = {
      event_properties: attributes.except(:user_id).compact,
      path: request&.path,
    }

    analytics_hash.merge!(request_attributes) if request

    lg_logger.track(event, analytics_hash)
  end

  def request_attributes
    attributes = {
      user_ip: request.remote_ip,
      hostname: request.host,
    }

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

  private

  def create_lg_logger
    @lg_logger || LGLogger.new(
      request: request,
      user: user,
      session: session,
    )
  end
end
