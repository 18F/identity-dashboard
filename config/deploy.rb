require 'net/ssh/proxy/command'
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
set :linked_files, %w(config/database.yml
                      config/saml.yml
                      config/secrets.yml)
set :linked_dirs, %w(log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system)
set :passenger_roles, [:app, :web]
set :passenger_restart_wait, 5
set :passenger_restart_runner, :sequence
set :rails_env, :production
set :repo_url, 'https://github.com/18F/identity-dashboard.git'
set :tmp_dir, '/tmp'

set :bastion_user, ENV['BASTION_USER'] || 'ubuntu'
set :ssh_options do
  ssh_command = "ssh -A #{fetch(:bastion_user)}@#{fetch(:bastion_host)} -W %h:%p"
  {
    proxy: Net::SSH::Proxy::Command.new(ssh_command),
    user: 'ubuntu'
  }
end

server 'apps_host', roles: %w(web app db)

namespace :deploy do
  desc 'Write deploy information to deploy.json'
  task :deploy_json do
    on roles(:web), in: :parallel do
      require 'json'
      require 'stringio'

      within current_path do
        deploy = {
          env: fetch(:stage),
          branch: fetch(:branch),
          user: fetch(:local_user),
          sha: fetch(:current_revision),
          timestamp: fetch(:release_timestamp)
        }

        execute :mkdir, '-p', 'public/api'

        # the #upload! method does not honor the values of #within at the moment
        # https://github.com/capistrano/sshkit/blob/master/EXAMPLES.md#upload-a-file-from-a-stream
        upload! StringIO.new(deploy.to_json), "#{current_path}/public/api/deploy.json"

        execute :chmod, '+r', 'public/api/deploy.json'
      end
    end
  end

  desc 'Modify permissions on /srv/dashboard'
  task :mod_perms do
    on roles(:web), in: :parallel do
      execute :sudo, :chown, '-R', 'ubuntu:nogroup', deploy_to
    end
  end

  after 'deploy:log_revision', :deploy_json
  after :deploy, 'deploy:mod_perms'
end
