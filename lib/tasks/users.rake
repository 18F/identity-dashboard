namespace :users do
  desc 'Promote a user in the dashboard to Login.gov admin'
  task make_admin: :environment do
    MakeAdmin.new(ENV['USER']).call
  end

  desc 'Clean up team memberships with incomplete info'
  task destroy_orphaned_memberships: :environment do
    logger = Logger.new(STDOUT)
    UserTeam.destroy_orphaned_memberships(logger:)
  end
end
