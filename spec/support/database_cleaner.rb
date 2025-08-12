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
    Team.initialize_teams { |_noop| }
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
