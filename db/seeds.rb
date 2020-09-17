# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# There are unique indexes on both agency name and agency id so we can't in-place update individual
# records without potentially causing unique constraint errors. What we do to get around this
# is to delete the ones we're going to update, and then re-create them.
#
# We do this all inside a transaction to provide continuity for other things that read the table.
Agency.transaction do
  Agency.where(
    id: Rails.application.config.agencies.map { |id, _values| id },
  ).delete_all

  Agency.where(
    name: Rails.application.config.agencies.map { |_id, values| values['name'] },
  ).delete_all

  Rails.application.config.agencies.each do |agency_id, values|
    Agency.create(id: agency_id, name: values['name'])
  end
end

if Rails.env.development? || Rails.env.test?
  User.find_or_create_by email: 'admin@gsa.gov' do |user|
    user.first_name = 'Addy'
    user.last_name = 'Ministrator'
    user.admin = true
  end
end
