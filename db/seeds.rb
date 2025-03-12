# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

AgencySeeder.new.run! unless Rails.env.test?

if Rails.env.development?
  User.find_or_create_by email: 'admin@gsa.gov' do |user|
    user.first_name = 'Addy'
    user.last_name = 'Ministrator'
    user.admin = true
  end
end

if ENV['KUBERNETES_REVIEW_APP'] == 'true'
  service_provider_seeder = ServiceProviderSeeder.new
  service_provider_seeder.write_review_app_yaml(dashboard_url: dashboard_url)
  service_provider_seeder.run
elsif Identity::Hostdata.config.prod_like_env == true
  ServiceProviderSeeder.new.run
end

Role.initialize_roles if Rails.env.test?
