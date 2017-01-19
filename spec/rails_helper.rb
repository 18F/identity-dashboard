ENV['RACK_ENV'] = 'test'

require 'spec_helper'

require File.expand_path('../../config/environment', __FILE__)
abort('DATABASE_URL environment variable is set') if ENV['DATABASE_URL']

require 'rspec/rails'
require 'pundit/rspec'

Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |file| require file }

RSpec.configure do |config|
  config.infer_base_class_for_anonymous_controllers = false
  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = false

  config.include Warden::Test::Helpers

  config.before(:suite) do
    Rails.application.load_seed
    Warden.test_mode!
  end

  config.before(:each) do
    stub_request(:any, /idp.example.com/).to_rack(FakeSamlIdp)
  end

  config.after(:each) do
    Warden.test_reset!
  end
end

ActiveRecord::Migration.maintain_test_schema!
