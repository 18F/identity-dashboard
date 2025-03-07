# frozen_string_literal: true

# require 'active_support/core_ext/hash/deep_merge'
require 'logger'
# require 'identity/hostdata'
require 'yaml'

module Deploy
  class Activate
    FILES_TO_LINK =
      %w[agencies iaa_gtcs iaa_orders integration_statuses integrations
         partner_account_statuses partner_accounts service_providers].freeze

    attr_reader :logger, :root

    def initialize(
      logger: default_logger,
      root: nil
    )
      @logger = logger
      @root = root
    end

    def run
      clone_idp_config

      setup_idp_config_symlinks
    end

    # Set up symlinks into identity-idp-config needed for the idp to make use
    # of relevant config and assets.
    #
    def setup_idp_config_symlinks
      FILES_TO_LINK.each do |file|
        symlink_verbose(
          File.join(root, idp_config_checkout_name, "#{file}.yml"),
          File.join(root, "config/#{file}.yml"),
        )
      end

      FileUtils.mkdir_p(idp_logos_dir)

      # Invalid symlinks can cause issues in the build process, so this step iterates through the
      # sp-logos directory in the IDP to delete any broken symlinks.
      # Dir.entries(idp_logos_dir).each do |name|
      #   next if name.start_with?('.')

      #   target = File.join(idp_logos_dir, name)
      #   FileUtils.rm(target) if File.symlink?(target) && !File.file?(target)
      # end
      # Public assets: sp-logos
      # Inject the logo files into the app's asset folder. deploy/activate is
      # run before deploy/build-post-config, so these will be picked up by the
      # rails asset pipeline.
      # Dir.entries(config_logos_dir).each do |name|
      #   next if name.start_with?('.')

        # target = File.join(config_logos_dir, name)
        # link = File.join(root, 'app/assets/images/sp-logos', name)
        # symlink_verbose(target, link, force: true)
        # link = File.join(root, 'public/assets/sp-logos', name)
        # symlink_verbose(target, link, force: true)
      # end
    end

    def root
      @root || File.expand_path('../..', __dir__)
    end

    def idp_logos_dir
      File.join(root, 'public/assets/sp-logos')
    end

    def config_logos_dir
      File.join(checkout_dir, 'public/assets/images/sp-logos')
    end

    def checkout_dir
      File.join(root, idp_config_checkout_name)
    end

    private

    # Clone the private-but-not-secret git repo
    def clone_idp_config
      private_git_repo_url = ENV.fetch(
        'IDP_private_config_repo',
        'git@github.com:18F/identity-idp-config.git',
      )

      cmd = ['git', 'clone', '--depth', '1', '--branch', 'main', private_git_repo_url, checkout_dir]
      logger.info('+ ' + cmd.join(' '))
      result = system(*cmd)
      raise "failed to execute command #{cmd.join(' ')}" unless result
    end

    def idp_config_checkout_name
      'identity-idp-config'
    end

    def symlink_verbose(dest, link, force: false)
      logger.info("symlink: #{link.inspect} => #{dest.inspect}")
      File.unlink(link) if force && File.exist?(link)
      File.symlink(dest, link)
    end

    def default_logger
      logger = Logger.new(STDOUT)
      logger.progname = 'deploy/activate'
      logger
    end
  end
end
