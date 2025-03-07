Rails.application.config.after_initialize do
  Role.initialize_roles if ActiveRecord::Base.connection.table_exists? 'roles'
rescue ActiveRecord::AdapterError
  # Don't require db initialization in contexts where the DB is not ready yet
end
