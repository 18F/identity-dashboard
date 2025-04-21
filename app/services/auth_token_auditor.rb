class AuthTokenAuditor
  EVENT_TAG = self.to_s.underscore.upcase

  attr_reader :logger

  def initialize(logger = nil)
    @logger = logger
    @logger ||= Rails.logger
  end

  def in_controller(controller, record = nil)
    email = controller.current_user.email
    url = controller.request.url
    method = "#{controller.class}##{controller.action_name}"
    logger.info("#{EVENT_TAG}: User #{email} running #{method} via #{url}")
  end

  def record_change(record)
    yield if block_given?
    logger.info(
      "#{EVENT_TAG}: Saved changes for #{record.user.email}",
    )
  end
end
