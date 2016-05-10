web: bundle exec puma -p $PORT -C ./config/puma.rb
worker: bundle exec rake jobs:work
mail: bundle exec mailcatcher -f --smtp-port 2025 --http-port 2080
