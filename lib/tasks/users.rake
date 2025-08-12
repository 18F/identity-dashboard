namespace :users do
  desc 'Promote a user in the dashboard to Login.gov admin'
  task make_admin: :environment do
    MakeAdmin.new(ENV['USER']).call
  end

  desc 'Clean up team memberships with incomplete info'
  task destroy_orphaned_team_memberships: :environment do
    logger = Logger.new(STDOUT)
    TeamMembership.destroy_orphaned_memberships(logger:)
  end

  desc 'Migrate old Login.gov Admin data representation to new Login.gov Admin data representation'
  task migrate_logingov_admins: :environment do
    logger = Logger.new(STDOUT)
    TeamMembership.migrate_logingov_admins(logger:)
  end
end
