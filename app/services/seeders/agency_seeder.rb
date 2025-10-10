# Agencies are static and should contain all Federal agencies
class Seeders::AgencySeeder
  attr_reader :agency_configs

  def initialize(agency_configs = Rails.application.config.agencies)
    @agency_configs = agency_configs
  end

  def run!
    # There are unique indexes on both agency name and agency id so we can't in-place update
    # individual records without potentially causing unique constraint errors. There are also
    # foreign key constraints with the service_providers table, so we can't just delete and recreate
    # records.
    #
    # Our approach is to detect pre-existing records that would conflict, and give them temporary
    # names, then run upserts to match the configuration
    #
    # We do this all inside a transaction to provide continuity for other things that read the rows.
    Agency.transaction do
      agencies_by_id = Agency.where(id: agency_configs.map { |id, _values| id }).to_a
      agencies_by_name = Agency.where(
        name: agency_configs.map { |_id, values| values['name'] },
      ).to_a

      agencies_in_db = (agencies_by_id + agencies_by_name).uniq(&:id)

      # Set temporary names for ones that may collide
      agencies_to_update = agencies_in_db.reject do |agency|
        agency.name == agency_configs[agency.id]['name']
      end
      agencies_to_update.each do |agency|
        agency.update!(name: SecureRandom.uuid)
      end

      # Update everything to match the YAML config
      Agency.upsert_all( # rubocop:disable Rails/SkipsModelValidations
        agency_configs.map { |agency_id, values| { id: agency_id, name: values['name'] } },
      )
    end
  end

  def seed_test
    Agency.find_or_create_by(self.class.internal_agency_data)
  end

  def self.internal_agency_data
    (id, details) = Rails.application.config.agencies.find do |_key, agency|
      agency['name'] == 'General Services Administration'
    end
    { id: id, name: details['name'] }
  end
end
