#################
# GLOBAL CONFIG
#################
set :application, 'dashboard'
# set branch based on env var or ask with the default set to the current local branch
set :branch, ENV['branch'] || ENV['BRANCH'] || ask(:branch, `git branch`.match(/\* (\S+)\s/m)[1])
set :bundle_without, 'deploy development doc test'
set :deploy_to, '/srv/dashboard'
set :deploy_via, :remote_cache
set :keep_releases, 5
set :linked_files, %w(.env
                      config/database.yml
                      config/saml.yml
                      config/secrets.yml)
set :linked_dirs, %w(bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system)
set :rails_env, :production
set :repo_url, 'https://github.com/18F/identity-dashboard.git'
set :ssh_options, forward_agent: false, user: 'ubuntu'
set :tmp_dir, '/srv/idp'

#########
# TASKS
#########
namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end
end
