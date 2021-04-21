require 'rack/timeout/base'

Rails.application.config.middleware.insert_before(
  Rack::Runtime,
  Rack::Timeout,
  service_timeout: IdentityConfig.store.rack_timeout_service_timeout_seconds,
)

if Rails.env.development?
  Rails.logger.info 'Disabling Rack::Timeout Logging'
  Rack::Timeout::Logger.disable
end
