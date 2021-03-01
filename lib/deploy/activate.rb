require 'active_support/core_ext/hash/deep_merge'
require 'logger'
require 'identity/hostdata'
require 'subprocess'
require 'yaml'

module Deploy
  class Activate
    attr_reader :logger, :s3_client

    def initialize(logger: default_logger, s3_client: nil)
      @logger = logger
      @s3_client = s3_client
    end

    def run
      download_application_yml_from_s3
      deep_merge_s3_data_with_example_application_yml
      set_proper_file_permissions_for_application_yml
    end

    private

    def download_application_yml_from_s3
      Identity::Hostdata.s3(logger: logger, s3_client: s3_client).download_configs(
        '/%<env>s/dashboard/v1/application.yml' => env_yaml_path
      )
    end

    def deep_merge_s3_data_with_example_application_yml
      File.open(result_yaml_path, 'w') { |file| file.puts YAML.dump(application_config) }
    end

    def set_proper_file_permissions_for_application_yml
      FileUtils.chmod(0o640, [env_yaml_path, result_yaml_path])
    end

    def application_config
      YAML.load_file(example_application_yaml_path).deep_merge(YAML.load_file(env_yaml_path))
    end

    def default_logger
      logger = Logger.new(STDOUT)
      logger.progname = 'deploy/activate'
      logger
    end

    def root
      File.expand_path('../..', __dir__)
    end

    def env_yaml_path
      File.join(root, 'config/application_s3_env.yml')
    end

    def example_application_yaml_path
      File.join(root, 'config/application.yml.example')
    end

    def result_yaml_path
      File.join(root, 'config/application.yml')
    end
  end
end
