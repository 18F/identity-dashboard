class ModelAuditor
  EVENT_TAG = self.to_s.underscore.upcase

  attr_reader :logger

  def initialize(logger: nil, controller:)
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
    logger.model_save record
  end
end
