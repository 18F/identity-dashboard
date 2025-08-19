require 'rails_helper'

RSpec.describe Seeders::AbstractSeeder do
  it 'uses the default logger when no logger passed' do
    expect(Seeders::AbstractSeeder.new.logger).to eq(Rails.logger)
  end

  it 'allows passing a null logger' do
    actual_logger = Seeders::AbstractSeeder.new(logger: Seeders::AbstractSeeder::NULL_LOGGER).logger
    expect(actual_logger).to be_a(Seeders::AbstractSeeder::NullLogger)
  end
end

