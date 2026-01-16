require 'rest-client'

# Loads data from the /api/deploy endpoint in our apps
class DeployStatusChecker
  Deploy = Struct.new(:app, :env, :host)

  Environment = Struct.new(:env, :statuses)

  DEPLOYS = YAML.load_file(Rails.root.join('config/status_checks.yml'))['deploys']
    .map { |deploy| Deploy.new(deploy['app'], deploy['env'], deploy['host']) }.freeze

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

    def short_name
      app.gsub('identity-', '')
    end

    def short_sha
      sha.first(8)
    end

    def commit_url
      "https://github.com/18F/#{app}/commits/#{sha}"
    end

    def pending_url
      "https://github.com/18F/#{app}/compare/#{sha}...main"
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
    status_from_json(deploy, JSON.parse(response.body))
  rescue StandardError => err
    status_from_error(deploy, "#{err.class}: #{err.message}")
  end

  # @return [Net::HTTPResponse]
  def load_status(deploy)
    uri = URI.join(deploy.host, '/api/deploy.json')

    req = RestClient::Request.new(url: uri.to_s, method: :get, timeout: 2)
    req.execute
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
