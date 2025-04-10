if ENV['COVERAGE']
  require 'simplecov'
  if ENV['COBERTURA_FORMATTER_ENABLED']
    require 'simplecov-cobertura'
    SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
  end
  SimpleCov.start 'rails' do
    enable_coverage :branch
    add_filter '/config/'
    add_filter %r{/vendor/ruby/}
    add_filter '/vendor/bundle/'
    add_filter %r{^/db/}
  end
end

ENV['RAILS_ENV'] ||= 'test'

require 'webmock/rspec'


# http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
    #  enable this if your test output is truncated
    # expectations.max_formatted_output_length = nil
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = :expect
    mocks.verify_partial_doubles = true
  end

  config.example_status_persistence_file_path = 'tmp/rspec_examples.txt'
  config.order = :random
end

WebMock.disable_net_connect!(
  allow: [
    /localhost/,
    /127\.0\.0\.1/,
  ],
)
