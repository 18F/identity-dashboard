# frozen_string_literal: true
require 'securerandom'

# `Logger` is a class in the standard library, so we need a custom name
class AnalyticsLogger
  attr_reader :request, :controller, :user, :options, :session

  def initialize(**options)
    @controller = options[:controller]
    @request = options[:request] || @controller.try(:request)
    @visit_token = options[:visit_token]
    @user = options[:user]
    @session = options[:session]
    @options = options
  end

  def analytics_logger
    @analytics_logger ||= ActiveSupport::Logger.new(
      Rails.root.join('log', IdentityConfig.store.event_log_filename),
    )
  end

  def track(name, properties = {}, options = {})
    data = {
      visit_token: visit_token,
      user_id: user.try(:uuid),
      user_role: user&.primary_role&.name,
      name: name.to_s,
      properties: properties,
      time: options[:time] || Time.current,
      event_id: options[:id] || generate_uuid,
    }.compact

    track_event(data)
  end

  def track_event(data)
    data[:visit_id] = data.delete(:visit_token)
    data[:log_filename] = IdentityConfig.store.event_log_filename

    log_event(data)
  end

  def visit_token
    session[:visit_token] ||= generate_uuid
  end

  protected

  def log_event(data)
    analytics_logger.info(data.to_json)
  end

  def generate_uuid
    SecureRandom.uuid
  end
end
