class RecordAuditor
  EVENT_TAG = self.to_s.underscore.upcase

  attr_reader :logger

  def initialize(controller:, logger: nil)
    @logger = logger
    @logger ||= EventLogger.new(
      user: controller.current_user,
      request: controller.request,
      session: controller.session,
      logger: logger,
    )
  end

  def record_change(record = nil, &)
    yield if block_given?
    logger.record_save record
  end
end
