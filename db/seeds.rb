# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Rails.env.test? ? Seeders::AgencySeeder.new.seed_test : Seeders::AgencySeeder.new.run!

Seeders::Roles.new.seed
Seeders::Teams.new.seed

if Rails.env.development? || ENV['POSTGRES_HOST']&.include?('.review-app')
  MakeAdmin.new('admin@gsa.gov,Addy,Ministrator').call
  Seeders::ReviewAppData.new.seed
end
