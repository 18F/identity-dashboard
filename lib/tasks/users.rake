namespace :users do
  desc 'Promote a user in the dashboard to Login.gov admin'
  task make_admin: :environment do
    MakeAdmin.new(ENV['USER']).call
  end
end
