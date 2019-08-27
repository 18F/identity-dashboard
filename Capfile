# Load DSL and Setup Up Stages
require 'capistrano/setup'

# Includes default deployment tasks
require 'capistrano/deploy'

# support for passenger
require 'capistrano/passenger'

# support for npm install
require 'capistrano/npm'

# support for bundler, rails/assets and rails/migrations
require 'capistrano/rails'

# support for new relic deploy updates
require 'new_relic/recipes'

# support for git
require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

# support for whenever
# require 'whenever/capistrano'

# Loads custom tasks from `lib/capistrano/tasks' if you have any defined.
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
