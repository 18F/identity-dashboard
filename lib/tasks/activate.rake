# frozen_string_literal: true
require_relative '../deploy/activate'

namespace :deploy do
  desc 'Run activate script'
  task :activate do
    worker = Deploy::Activate.new(root: File.expand_path('../', __dir__))
    worker.run
  end
end
