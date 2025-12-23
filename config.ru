require File.expand_path('config/environment', __dir__)

use Rack::ContentLength
run Rails.application
