web: bundle exec rackup config.ru --port ${PORT:-3000}
worker: bundle exec rake jobs:work
mail: bundle exec mailcatcher -f --smtp-port 2025 --http-port 2080
