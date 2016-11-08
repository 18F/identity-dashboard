# Loads data from the /api/deploy endpoint in our deploys of identity-idp
class DeployStatusChecker
  Deploy = Struct.new(:app, :env, :host)

  Environment = Struct.new(:env, :statuses)

  DEPLOYS = [
    Deploy.new('identity-idp', 'prod'),
    Deploy.new('identity-sp-rails', 'prod'),
    Deploy.new('identity-sp-sinatra', 'prod'),
    Deploy.new('identity-dashboard', 'prod'),

    Deploy.new('identity-idp', 'demo', 'idp.demo.login.gov'),
    Deploy.new('identity-sp-rails', 'demo', 'sp.demo.login.gov'),
    Deploy.new('identity-sp-sinatra', 'demo', 'sp-sinatra.demo.login.gov'),
    Deploy.new('identity-dashboard', 'demo', 'dashboard.demo.login.gov'),

    Deploy.new('identity-idp', 'qa', 'idp.qa.login.gov'),
    Deploy.new('identity-sp-rails', 'qa', 'sp.qa.login.gov'),
    Deploy.new('identity-sp-sinatra', 'qa', 'sp-sinatra.qa.login.gov'),
    Deploy.new('identity-dashboard', 'qa', 'dashboard.qa.login.gov'),

    Deploy.new('identity-idp', 'dev', 'idp.dev.login.gov'),
    Deploy.new('identity-sp-rails', 'dev', 'sp.dev.login.gov'),
    Deploy.new('identity-sp-sinatra', 'dev', 'sp-sinatra.dev.login.gov'),
    Deploy.new('identity-dashboard', 'dev', 'dashboard.dev.login.gov')
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
    uri = deploy_uri(deploy)

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new(uri)
      basic_auth(request)
      http.request(request)
    end
  end

  # @return [URI]
  def deploy_uri(deploy)
    use_ssl = (deploy.env != 'local')
    URI("#{use_ssl ? 'https' : 'http'}://#{deploy.host}/api/deploy.json")
  end

  def basic_auth(request)
    request.basic_auth Rails.application.secrets.http_auth_username,
                       Rails.application.secrets.http_auth_password
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
