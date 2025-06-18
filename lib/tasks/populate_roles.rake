namespace :memberships do
  desc 'Update legacy permissions to roles'
  task populate_roles: :environment do
    logger = Logger.new(STDOUT)
    PopulateRoles.new(logger).call
  end
end