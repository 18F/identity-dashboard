Rails.application.config.after_initialize do
  Role.initialize_roles if ActiveRecord::Base.connection.table_exists? 'roles'
end
