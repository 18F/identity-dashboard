require ::File.expand_path('../config/environment', __FILE__)

use Rack::ContentLength
run Rails.application
