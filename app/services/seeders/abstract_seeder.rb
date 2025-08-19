class Seeders::AbstractSeeder
  attr_reader :logger

  class NullLogger
    def info
    end
  end

  DEFAULT_LOGGER = Rails.logger
  NULL_LOGGER = NullLogger.new

  def initialize(logger: nil)
    @logger = logger
    @logger ||= DEFAULT_LOGGER
  end
end