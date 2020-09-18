# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

AgencySeeder.new.run!

if Rails.env.development? || Rails.env.test?
  User.find_or_create_by email: 'admin@gsa.gov' do |user|
    user.first_name = 'Addy'
    user.last_name = 'Ministrator'
    user.admin = true
  end
end
