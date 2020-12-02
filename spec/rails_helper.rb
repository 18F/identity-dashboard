ENV['RACK_ENV'] = 'test'

require 'spec_helper'
require File.expand_path('../config/environment', __dir__)

require 'rspec/rails'
require 'pundit/rspec'
require 'paper_trail/frameworks/rspec'

Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |file| require file }

RSpec.configure do |config|
  config.infer_base_class_for_anonymous_controllers = false
  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = true

  config.include Warden::Test::Helpers

  config.before(:suite) do
    Warden.test_mode!
  end

  config.after(:suite) do
    remove_uploaded_files
  end

  config.before(:each) do
    stub_request(:any, /idp.example.com/).to_rack(FakeSamlIdp)
  end

  config.after(:each) do
    Warden.test_reset!
  end
end

def remove_uploaded_files
  FileUtils.rm_rf(Rails.root.join('tmp', 'storage'))
end

ActiveRecord::Migration.maintain_test_schema!
