RSpec.configure do |config|
  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = DatabaseCleaner::ActiveRecord::Truncation.new(
      except: ['roles'],
    )
  end

  config.before(:each) do
    Seeders::Teams.new(logger: Seeders::Teams::NULL_LOGGER).seed
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
