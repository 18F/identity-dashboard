require 'login_gov/hostdata'
require 'subprocess'

class ServiceProviderLogoUpdater
  include ServiceProviderHelper

  # :reek:TooManyStatements
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def import_logos_to_active_storage
    return unless Figaro.env.logo_upload_enabled

    git_latest_idp_config
    idp_config.each do |sp|
      issuer = sp['issuer']
      logo_name = sp['logo']
      logger.info('~~ ' + issuer.to_s + ' logo: ' + logo_name.to_s)
      next unless logo_name.present? && valid_image_type?(logo_name)

      service_provider = ServiceProvider.find_by(issuer: issuer)
      next unless service_provider

      logo_path = Rails.root.join(
        'identity-idp-config',
        'public',
        'assets',
        'images',
        'sp-logos',
        logo_name
      )
      service_provider.logo_file.attach(
        io: File.open(logo_path),
        filename: logo_name,
        content_type: mime_type(logo_name)
      )
    end
  rescue StandardError => error
    handle_error(error)
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  #############################################################################

  # Clone the private-but-not-secret git repo
  def git_latest_idp_config
    if File.directory? repo_dir
      update_repo
    else
      clone_repo
    end
  end

  def idp_config
    @idp_config ||= load_idp_config
  end

  def handle_error(error)
    # ::NewRelic::Agent.notice_error(error)
    logger.error(error)
  end

  #############################################################################

  def update_repo
    cmd = ['cd', repo_dir, ';', 'git', 'pull']
    logger.info(cmd.join(' '))
    Subprocess.check_call(cmd)
  end

  def clone_repo
    repo_url = ENV.fetch('IDP_private_config_repo',
                         'git@github.com:18F/identity-idp-config.git')
    cmd = ['git', 'clone', repo_url, repo_dir]
    logger.info(cmd.join(' '))
    Subprocess.check_call(cmd)
  end

  def load_idp_config
    url = dashboard_sp_url

    req = RestClient::Request.new(url: url, method: :get, timeout: 2)
    response = req.execute
    JSON.parse(response.body)
  end

  def logger
    @logger ||= default_logger
  end

  #############################################################################

  def repo_dir
    @repo_dir ||= Rails.root.join(idp_config_checkout_name)
  end

  # :reek:UtilityFunction
  def dashboard_sp_url
    if LoginGov::Hostdata.in_datacenter?
      env = LoginGov::Hostdata.env
      domain = LoginGov::Hostdata.domain
      "https://dashboard.#{env}.#{domain}/api/service_providers"
    else
      'http://localhost:3001/api/service_providers'
    end
  end

  # :reek:UtilityFunction
  def default_logger
    logger = Logger.new(STDOUT)
    logger.progname = 'import_logos_to_active_storage'
    logger
  end

  #############################################################################

  # :reek:UtilityFunction
  def idp_config_checkout_name
    'identity-idp-config'.freeze
  end
end
