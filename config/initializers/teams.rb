Rails.application.config.after_initialize do
  Team.initialize_teams if ActiveRecord::Base.connection.table_exists? 'groups'
rescue ActiveRecord::AdapterError
  # Don't require db initialization in contexts where the DB is not ready yet
end
