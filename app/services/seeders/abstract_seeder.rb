class Seeders::AbstractSeeder
  attr_reader :logger

  DEFAULT_LOGGER = Rails.logger

  def initialize(logger: nil)
    @logger = logger
    @logger ||= DEFAULT_LOGGER
  end
end
