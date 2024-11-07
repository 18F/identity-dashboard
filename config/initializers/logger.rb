EVENT_LOG_FILENAME = 'events.log'

class Logger
  def logger
    @logger ||= ActiveSupport::Logger.new(
      Rails.root.join('log', EVENT_LOG_FILENAME)
    )
  end

  def track_event(data)
    data[:id] = 'event_id'
    data[:visitor_id] = 'visitor_token'
    data[:visit_id] = 'visit_token'
    data[:log_filename] = EVENT_LOG_FILENAME

    log_event(data)
  end

  protected

  def log_event(data)
    logger.info(data.to_json)
  end
end
