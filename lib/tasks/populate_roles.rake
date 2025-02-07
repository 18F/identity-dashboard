namespace :user_teams do
  desc 'Update legacy permissions to roles'
  task populate_roles: :environment do
    PopulateRoles.new().call
  end
end