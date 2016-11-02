# Loads data from the /api/deploy endpoint in our deploys of identity-idp
class DeployStatusChecker
  Deploy = Struct.new(:env, :host)

  DEPLOYS = [
    Deploy.new('prod'),
    Deploy.new('demo', 'idp.demo.login.gov'),
    Deploy.new('dev', 'idp.dev.login.gov'),
    Deploy.new('qa', 'idp.qa.login.gov')
  ].freeze

  Status = Struct.new(:env, :host, :sha, :branch, :user, :timestamp, :error) do
    def status_class
      if !host
        'deploy-bg-loading'
      elsif error
        'deploy-bg-error'
      else
        'deploy-bg-success'
      end
    end

    def short_sha
      sha.first(8)
    end

    def commit_url
      "https://github.com/18F/identity-idp/commits/#{sha}"
    end
  end

  # @return [Array<Status>]
  def check!
    DEPLOYS.map { |deploy| Thread.new { status(deploy) } }.map(&:value)
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
    URI("#{use_ssl ? 'https' : 'http'}://#{deploy.host}/api/deploy")
  end

  def basic_auth(request)
    request.basic_auth Rails.application.secrets.http_auth_username,
                       Rails.application.secrets.http_auth_password
  end

  # @return [Status]
  def status_from_json(deploy, json)
    Status.new.tap do |status|
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
      status.env = deploy.env
      status.host = deploy.host
      status.error = message
    end
  end
end
