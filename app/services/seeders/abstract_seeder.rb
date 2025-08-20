class Seeders::AbstractSeeder
  attr_reader :logger

  DEFAULT_LOGGER = Rails.logger

  def initialize(logger: DEFAULT_LOGGER)
    @logger = logger
  end
end
