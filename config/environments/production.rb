require Rails.root.join('config/smtp')
Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.serve_static_files = Figaro.env.serve_static_files == 'true'
  config.middleware.use Rack::Deflater
  config.assets.compile = false
  config.assets.digest = true
  config.log_level = :debug
  config.action_controller.asset_host = Figaro.env.asset_host
  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify
  config.log_formatter = ::Logger::Formatter.new
  config.active_record.dump_schema_after_migration = false
end
Rack::Timeout.timeout = 60
