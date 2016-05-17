web: bundle exec puma -C ./config/puma.rb --port 3001
worker: bundle exec rake jobs:work
mail: bundle exec mailcatcher -f --smtp-port 2025 --http-port 2080
