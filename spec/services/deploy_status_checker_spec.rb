require 'rails_helper'

RSpec.describe DeployStatusChecker do
  include DeployStatusCheckerHelper

  subject(:checker) { DeployStatusChecker.new }

  describe DeployStatusChecker::Status do
    let(:host) { 'foo.bar' }
    let(:error) { nil }

    subject(:status) do
      DeployStatusChecker::Status.new.tap do |status|
        status.env = 'prod'
        status.host = host
        status.app = 'identity-idp'
        status.sha = '1234567890abcdef'
        status.error = error
      end
    end

    describe '#short_sha' do
      it 'is the first few characters of the sha' do
        expect(status.short_sha).to eq('12345678')
      end
    end

    describe '#short_name' do
      it 'remove the identity- part of the app name' do
        expect(status.short_name).to eq('idp')
      end
    end

    describe '#commit_url' do
      it 'links to the the commit on Github' do
        expect(status.commit_url).
          to eq('https://github.com/18F/identity-idp/commits/1234567890abcdef')
      end
    end

    describe '#pending_url' do
      it 'links to the compare link on Github' do
        expect(status.pending_url).
          to eq('https://github.com/18F/identity-idp/compare/1234567890abcdef...main')
      end
    end

    describe '#status_class' do
      context 'with no host' do
        let(:host) { nil }

        it { expect(status.status_class).to eq('deploy-disabled') }
      end

      context 'with an error' do
        let(:error) { 'error' }

        it { expect(status.status_class).to eq('deploy-error') }
      end

      context 'with a host and no error' do
        it { expect(status.status_class).to eq('deploy-success') }
      end
    end
  end

  describe '#check!' do
    before do
      stub_deploy_status
    end

    it 'loads statuses from the environments and swallows error' do
      statuses = checker.check!

      int = statuses.find { |status| status.env == 'int' }
      int_status = int.statuses.first
      expect(int_status.sha).to eq(stub_status_json['sha'])

      dev = statuses.find { |status| status.env == 'dev' }
      dev_status = dev.statuses.first
      expect(dev_status.sha).to be_nil
      expect(dev_status.error).to eq('RestClient::NotFound: 404 Not Found')
    end
  end

  describe '#status_from_json' do
    let(:deploy) { DeployStatusChecker::Deploy.new('prod', 'foo.bar') }

    let(:json) do
      {
        env: 'qa',
        branch: 'main',
        user: 'user',
        sha: '5184dcc8c413adffd7cd622ab55ac36b4b219163',
        timestamp: '20161102201213',
      }.as_json
    end

    subject(:status) { checker.status_from_json(deploy, json) }

    it 'sets the env and host from the deploy' do
      expect(status.env).to eq(deploy.env)
      expect(status.host).to eq(deploy.host)
    end

    it 'sets the sha, branch and user' do
      expect(status.sha).to eq(json['sha'])
      expect(status.branch).to eq(json['branch'])
      expect(status.user).to eq(json['user'])
    end

    it 'parses the timestamp' do
      expect(status.timestamp).to eq(Time.zone.local(2016, 11, 2, 20, 12, 13))
    end
  end

  describe '#status_from_error' do
    let(:deploy) { DeployStatusChecker::Deploy.new('prod', 'foo.bar') }
    let(:error) { 'error message' }

    subject(:status) { checker.status_from_error(deploy, error) }

    it 'sets the env and host from the deploy' do
      expect(status.env).to eq(deploy.env)
      expect(status.host).to eq(deploy.host)
    end

    it 'builds a status object with the error' do
      expect(status.error).to eq(error)
    end
  end
end
