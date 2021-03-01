require 'rails_helper'

RSpec.describe ServiceProviderLogoUpdater do
  include ServiceProviderHelper

  subject(:updater) { ServiceProviderLogoUpdater.new }

  let(:service_provider) { create(:service_provider, :with_team, logo: 'logo.svg') }
  let(:fake_config) { [service_provider.attributes] }
  let(:fake_response) do
    OpenStruct.new(
      body: JSON.generate(fake_config)
    )
  end

  before do
    # look for logos in the fixtures
    allow(updater).to receive(:logo_path) do |filename|
      Rails.root.join('spec', 'fixtures', filename)
    end

    # don't actually set s3 object's acl
    allow_any_instance_of(Aws::S3::Client).to receive(:copy_object)
    allow(updater).to receive(:s3).and_return(Aws::S3::Client.new(stub_responses: true))
  end

  describe '#import_logos_to_active_storage' do
    it 'attaches the legacy logo to the service provider' do
      # don't clone the config repo
      allow(Subprocess).to receive(:check_call).and_return(true)
      # don't call /api/service_providers on the dashboard
      # allow(updater).to receive(:load_idp_config).and_return(fake_config)
      allow_any_instance_of(RestClient::Request).to receive(:execute).and_return(fake_response)
      # Just to bump up code coverage -- doesn't affect the test
      allow(Identity::Hostdata).to receive(:in_datacenter?).and_return(true)
      allow(Identity::Hostdata).to receive(:env).and_return('int')
      allow(Identity::Hostdata).to receive(:domain).and_return('identitysandbox.gov')

      updater.import_logos_to_active_storage
      service_provider.reload

      expect(service_provider).to be_valid
      expect(service_provider.logo_file).to be_attached
    end

    it 'handles edge cases' do
      allow(Subprocess).to receive(:check_call).and_return(true)
      allow(File).to receive(:directory?).and_return(true)
      allow(Identity::Hostdata).to receive(:in_datacenter?).and_return(false)
      # don't call /api/service_providers on the dashboard
      # allow(updater).to receive(:load_idp_config).and_return(fake_config)
      allow_any_instance_of(RestClient::Request).to receive(:execute).and_return(fake_response)

      updater.import_logos_to_active_storage
      service_provider.reload

      expect(service_provider).to be_valid
      expect(service_provider.logo_file).not_to be_attached
    end
  end
end
