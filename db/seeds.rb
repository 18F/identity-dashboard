# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Rails.env.test? ? Seeders::AgencySeeder.new.seed_test : Seeders::AgencySeeder.new.run!

if Rails.env.development?
  User.find_or_create_by email: 'admin@gsa.gov' do |user|
    user.first_name = 'Addy'
    user.last_name = 'Ministrator'
    user.admin = true
  end
end

Seeders::Roles.new.seed
Seeders::Teams.new.seed
