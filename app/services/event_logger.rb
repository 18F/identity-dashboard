# frozen_string_literal: true

require 'securerandom'

# `Logger` is a class in the standard library, so we need a custom name
class EventLogger
  include LogEvents

  attr_reader :request, :response, :user, :session

  # @param request [ActionDispatch::Request, Rack::Request, nil]
  #   When {#track_event} gets called, `EventLogger` will try to include
  #   browser information from the request.
  # @param response [ActionDispatch::Response, Rack::Response, nil]
  # @param user [User,nil]
  # @param session
  #   A Hash-like object. Exact class can vary by environment because different environments can use
  #   different session store types.
  #   If blank, `EventLogger` will try to get the session from the `:request` option
  # @param logger A destination to log events.
  #   If blank, `EventLogger` will try to use the `log` folder and open a file base on
  #   the value of `IdentityConfig.store.event_log_filename`
  # @raise [SystemCallError] Can raise an error when using the default logger and log_filename
  #   can't be created. For actions that should fail if they can't be logged, make sure to
  #    initialize this class first so that the raised error will interrupt normal flow.
  def initialize(request: nil, response: nil, user: nil, session: nil, logger: nil)
    @request = request
    @response = response
    @user = user
    @session = session || @request.try(:session) || {}
    @logger = logger || default_logger
  end

  # Log a specific event
  # @param [#to_s] name The name of the event to track
  # @param [Hash, nil] properties Arbitrary, optional properties that can be added to the event.
  #   These will show up in the logged event as properties -> event_properties -> <key,value pairs>.
  #   Properties with null values will be omitted.
  # @return [Boolean] true on log event success
  def track_event(name, properties = {})
    data = {
      visit_id: visit_token,
      user_id: user.try(:uuid),
      user_role: user&.primary_role&.name,
      name: name.to_s,
      properties: {
        event_properties: properties.compact,
        path: request&.path,
      }.compact,
      time: Time.current,
      event_id: generate_uuid,
      status: response.try(:status),
    }.compact

    data.merge!(request_attributes) if request

    log_event(data)
  end

  # Return the current visit token or generate and assign a new one
  # @return [String]
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
      user_ip: request.try(:remote_ip),
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

  def default_logger
    result = begin
      ActiveSupport::Logger.new(
        Rails.root.join('log', IdentityConfig.store.event_log_filename),
      )
    rescue SystemCallError => err
      # Hard fail unless we're definitely a review app, like if our database is in the K8s cluster
      raise err unless ENV['POSTGRES_HOST']&.include?('.review-app')

      # If we're a review app, events won't get pulled into Cloudwatch regardless, so it's OK
      # to fall back to using the built-in logger
      Rails.logger
    end
    result.formatter = Rails.logger.formatter
    result
  end
end
