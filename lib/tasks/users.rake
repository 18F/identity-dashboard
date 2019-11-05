namespace :users do
  desc 'Promote a user in the dashboard to admin'
  task make_admin: :environment do
    MakeAdmin.new(ENV['USER']).call
  end
end
