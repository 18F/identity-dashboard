# frozen_string_literal: true
require 'utf8_cleaner'
require 'securerandom'

EVENT_LOG_FILENAME = 'events.log'

class LGLogger
  attr_reader :request, :controller, :user, :options, :session

  def initialize(**options)
    @controller = options[:controller]
    @request = options[:request] || @controller.try(:request)
    @visit_token = options[:visit_token]
    @user = options[:user]
    @session = options[:session]
    @options = options
  end

  def lg_logger
    @lg_logger ||= ActiveSupport::Logger.new(
      Rails.root.join('log', EVENT_LOG_FILENAME)
    )
  end

  def track(name, properties = {}, options = {})
    data = {
      visit_token: visit_token,
      user_id: user.try(:uuid),
      name: name.to_s,
      properties: properties,
      time: trusted_time(options[:time]),
      event_id: options[:id] || generate_uuid
    }.select { |_, v| v }

    track_event(data)
  end

  def track_event(data)
    data[:visit_id] = data.delete(:visit_token)
    data[:log_filename] = EVENT_LOG_FILENAME

    log_event(data)
  end

  def visit_token
    session[:visit_token] ||= ensure_token(generate_uuid)
  end

  protected

  def log_event(data)
    lg_logger.info(data.to_json)
  end

  def generate_uuid
    SecureRandom.uuid
  end

  def trusted_time(time = nil)
    time || Time.current
  end

  def ensure_token(token)
    token = Utf8Cleaner.new(token).remove_invalid_utf8_bytes
    token.to_s.gsub(/[^a-z0-9\-]/i, "").first(64) if token
  end
end
