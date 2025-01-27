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
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = :expect
    mocks.verify_partial_doubles = true
  end

  config.example_status_persistence_file_path = 'tmp/rspec_examples.txt'
  config.order = :random
end

RSpec.shared_context 'with a user for each role' do
  let(:site_admin) { create(:admin) }
  let(:team) { create(:team) }
  let(:partner_admin) { create(:user_team, :partner_admin, team:).user }
  let(:partner_developer) { create(:user_team, :partner_developer, team:).user }
  let(:partner_readonly) { create(:user_team, :partner_readonly, team:).user }
  let(:non_team_member) { create(:restricted_ic) }

  shared_examples_for 'allows all team members except Partner Readonly for `object`' do
    it 'forbids Partner Readonly' do
      expect(described_class).to_not permit(partner_readonly, object)
    end

    it 'forbids non-team-member users' do
      expect(described_class).to_not permit(non_team_member, object)
    end

    it 'allows Site Admin' do
      expect(described_class).to permit(site_admin, object)
    end

    it 'allows Partner Admin' do
      expect(described_class).to permit(partner_admin, object)
    end

    it 'allows Partner Developer' do
      expect(described_class).to permit(partner_developer, object)
    end
  end

  shared_examples_for 'allows site admins only for `object`' do
    it 'allows admin' do
      expect(described_class).to permit(site_admin, object)
    end

    it 'forbids Partner Admin' do
      expect(described_class).to_not permit(partner_admin, object)
    end

    it 'forbids Partner Developer' do
      expect(described_class).to_not permit(partner_developer, object)
    end

    it 'forbids Partner Readonly' do
      expect(described_class).to_not permit(partner_readonly, object)
    end

    it 'forbids non-team-member users' do
      expect(described_class).to_not permit(non_team_member, object)
    end
  end
end

RSpec.configure do |config|
  config.include_context('with a user for each role', type: :policy)
end

WebMock.disable_net_connect!(
  allow: [
    /localhost/,
    /127\.0\.0\.1/,
    /codeclimate.com/, # For uploading coverage reports
  ],
)
