require 'rack/timeout/base'

Rails.application.config.middleware.insert_before(
  Rack::Runtime,
  Rack::Timeout,
  service_timeout: Figaro.env.rack_timeout_service_timeout_seconds.to_i,
)

if Rails.env.development?
  Rails.logger.info 'Disabling Rack::Timeout Logging'
  Rack::Timeout::Logger.disable
end
