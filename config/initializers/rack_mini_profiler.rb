if ENV.fetch('RACK_MINI_PROFILER', 0).positive?
  require 'rack-mini-profiler'

  Rack::MiniProfilerRails.initialize!(Rails.application)
end
