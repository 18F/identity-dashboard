# frozen_string_literal: true
require 'securerandom'

# `Logger` is a class in the standard library, so we need a custom name
class EventLogger
  include LogEvents

  attr_reader :request, :controller, :user, :options, :session

  def initialize(**options)
    @controller = options[:controller]
    @request = options[:request] || @controller.try(:request)
    @user = options[:user] || @controller.try(:user)
    @session = options[:session] || @controller.try(:session)
    @logger = options[:logger] || Rails.logger
    @options = options
  end

  def track_event(name, properties = {}, options = {})
    data = {
      log_filename: IdentityConfig.store.event_log_filename,
      visit_id: visit_token,
      user_id: user.try(:uuid),
      user_role: user&.primary_role&.name,
      name: name.to_s,
      properties: {
        event_properties: properties.compact,
        path: request&.path,
      }.compact,
      time: options[:time] || Time.current,
      event_id: options[:id] || generate_uuid,
    }.compact

    data.merge!(request_attributes) if request

    log_event(data)
  end

  def visit_token
    session[:visit_token] ||= generate_uuid
  end

  private

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

  def request_attributes
    attributes = {
      user_ip: request.remote_ip,
      hostname: request.host,
    }

    attributes.merge!(browser_attributes)
  end

  protected

  def log_event(data)
    @logger.info(data.to_json)
  end

  def browser
    @browser ||= BrowserCache.parse(request.user_agent)
  end

  def generate_uuid
    SecureRandom.uuid
  end
end
