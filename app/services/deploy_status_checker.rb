# Loads data from the /api/deploy endpoint in our deploys of identity-idp
class DeployStatusChecker
  Deploy = Struct.new(:app, :env, :host)

  Environment = Struct.new(:env, :statuses)

  DEPLOYS = [
    Deploy.new('identity-idp', 'prod', 'https://secure.login.gov'),
    Deploy.new('identity-sp-rails', 'prod'),
    Deploy.new('identity-sp-sinatra', 'prod'),
    Deploy.new('identity-dashboard', 'prod'),

    Deploy.new('identity-idp', 'staging', 'https://idp.staging.login.gov'),
    Deploy.new('identity-sp-rails', 'staging'),
    Deploy.new('identity-sp-sinatra', 'staging'),
    Deploy.new('identity-dashboard', 'staging'),

    Deploy.new('identity-idp', 'pt', 'https://idp.pt.login.gov'),
    Deploy.new('identity-sp-rails', 'pt', 'https://sp.pt.login.gov'),
    Deploy.new('identity-sp-sinatra', 'pt', 'https://sp-sinatra.pt.login.gov'),
    Deploy.new('identity-dashboard', 'pt', 'https://dashboard.pt.login.gov'),

    Deploy.new('identity-idp', 'int', 'https://idp.int.login.gov'),
    Deploy.new('identity-sp-rails', 'int', 'https://sp.int.login.gov'),
    Deploy.new('identity-sp-sinatra', 'int', 'https://sp-sinatra.int.login.gov'),
    Deploy.new('identity-dashboard', 'int', 'https://dashboard.int.login.gov'),

    Deploy.new('identity-idp', 'qa', 'https://idp.qa.login.gov'),
    Deploy.new('identity-sp-rails', 'qa', 'https://sp.qa.login.gov'),
    Deploy.new('identity-sp-sinatra', 'qa', 'https://sp-sinatra.qa.login.gov'),
    Deploy.new('identity-dashboard', 'qa', 'https://dashboard.qa.login.gov'),

    Deploy.new('identity-idp', 'dev', 'https://idp.dev.login.gov'),
    Deploy.new('identity-sp-rails', 'dev', 'https://sp.dev.login.gov'),
    Deploy.new('identity-sp-sinatra', 'dev', 'https://sp-sinatra.dev.login.gov'),
    Deploy.new('identity-dashboard', 'dev', 'https://dashboard.dev.login.gov')
  ].freeze

  Status = Struct.new(:app, :env, :host, :sha, :branch, :user, :timestamp, :error) do
    def status_class
      if !host
        'deploy-disabled'
      elsif error
        'deploy-error'
      else
        'deploy-success'
      end
    end

    def short_sha
      sha.first(8)
    end

    def commit_url
      "https://github.com/18F/#{app}/commits/#{sha}"
    end

    def pending_url
      "https://github.com/18F/#{app}/compare/#{sha}...master"
    end
  end

  # @return [Array<Environment>]
  def check!
    deploys = DEPLOYS.map { |deploy| Thread.new { status(deploy) } }.map(&:value)

    deploys.group_by(&:env).map { |env, statuses| Environment.new(env, statuses) }
  end

  # @return [Status]
  def status(deploy)
    return status_from_error(deploy, 'no host') if deploy.host.nil?

    response = load_status(deploy)

    if response.code.to_i == 200
      status_from_json(deploy, JSON.parse(response.body))
    else
      status_from_error(deploy, response.code)
    end
  rescue => error
    status_from_error(deploy, error.message)
  end

  # @return [Net::HTTPResponse]
  def load_status(deploy)
    uri = URI.join(deploy.host, '/api/deploy.json')

    options = { use_ssl: uri.scheme == 'https', open_timeout: 2, read_timeout: 2 }
    Net::HTTP.start(uri.host, uri.port, options) do |http|
      request = Net::HTTP::Get.new(uri.request_uri)
      basic_auth(request)
      http.request(request)
    end
  end

  def basic_auth(request)
    request.basic_auth(Figaro.env.basic_auth_username,
                       Figaro.env.basic_auth_password)
  end

  # @return [Status]
  def status_from_json(deploy, json)
    Status.new.tap do |status|
      status.app = deploy.app
      status.env = deploy.env
      status.host = deploy.host
      status.sha = json['sha']
      status.branch = json['branch']
      status.user = json['user']
      status.timestamp = Time.zone.parse(json['timestamp'])
    end
  end

  # @return [Status]
  def status_from_error(deploy, message)
    Status.new.tap do |status|
      status.app = deploy.app
      status.env = deploy.env
      status.host = deploy.host
      status.error = message
    end
  end
end
