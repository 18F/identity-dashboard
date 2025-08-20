require 'rails_helper'

RSpec.describe Seeders::AbstractSeeder do
  it 'uses the default logger when no logger passed' do
    test_string = "random string #{rand(1..1000)}"
    expect(Rails.logger).to receive(:info).with(test_string)
    described_class.new.logger.info test_string
  end

  it 'allows specifying a logger' do
    logger = object_double(Logger.new(nil))
    test_string = "random string #{rand(1..1000)}"
    expect(logger).to receive(:warn).with(test_string)
    described_class.new(logger:).logger.warn test_string
  end
end
