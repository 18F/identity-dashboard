require 'rails_helper'

RSpec.describe DeployStatusChecker do
  subject(:checker) { DeployStatusChecker.new }

  describe DeployStatusChecker::Status do
    let(:host) { 'foo.bar' }
    let(:error) { nil }

    subject(:status) do
      DeployStatusChecker::Status.new.tap do |status|
        status.env = 'prod'
        status.host = host
        status.sha = '1234567890abcdef'
        status.error = error
      end
    end

    describe '#short_sha' do
      it 'is the first few characters of the sha' do
        expect(status.short_sha).to eq('12345678')
      end
    end

    describe '#commit_url' do
      it 'links to the the commit on Github' do
        expect(status.commit_url).
          to eq('https://github.com/18F/identity-idp/commits/1234567890abcdef')
      end
    end

    describe '#status_class' do
      context 'with no host' do
        let(:host) { nil }
        it { expect(status.status_class).to eq('deploy-bg-loading') }
      end

      context 'with an error' do
        let(:error) { 'error' }
        it { expect(status.status_class).to eq('deploy-bg-error') }
      end

      context 'with a host and no error' do
        it { expect(status.status_class).to eq('deploy-bg-success') }
      end
    end
  end

  describe '#check!' do
    let(:status_json) do
      {
        sha: 'sha',
        branch: 'branch',
        user: 'user',
        timestamp: '20161102201213'
      }.as_json
    end

    before do
      stub_request(:get, 'https://idp.demo.login.gov/api/deploy').
        to_return(body: status_json.to_json)
      stub_request(:get, 'https://idp.dev.login.gov/api/deploy').
        to_return(status: 404)
      stub_request(:get, 'https://idp.qa.login.gov/api/deploy').
        to_timeout
    end

    it 'loads statuses from the environments and swallows error' do
      statuses = checker.check!

      prod = statuses.find { |status| status.env == 'prod' }
      expect(prod.host).to be_nil
      expect(prod.error).to eq('no host')

      demo = statuses.find { |status| status.env == 'demo' }
      expect(demo.sha).to eq(status_json['sha'])

      dev = statuses.find { |status| status.env == 'dev' }
      expect(dev.sha).to be_nil
      expect(dev.error).to eq('404')

      qa = statuses.find { |status| status.env == 'qa' }
      expect(qa.sha).to be_nil
      expect(qa.error).to eq('execution expired')
    end
  end

  describe '#status_from_json' do
    let(:deploy) { DeployStatusChecker::Deploy.new('prod', 'foo.bar') }

    let(:json) do
      {
        env: 'qa',
        branch: 'master',
        user: 'user',
        sha: '5184dcc8c413adffd7cd622ab55ac36b4b219163',
        timestamp: '20161102201213'
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
