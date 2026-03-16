# The Extract tool is used for migrating ServiceProvider data from `int`
# to `prod`.
class Extract
  include ActiveModel::Model

  attr_accessor :ticket, :criteria_file, :criteria_list

  validates :ticket, presence: true
  validate :file_and_or_list
  validates :service_providers, presence: true

  # @param [String] ticket identifier used in file name
  # @param [String] criteria_list comma- and/or space-separated string
  # @param [File<text/plain>] criteria_file comma- and/or space-separated plaintext
  def initialize(ticket: '', criteria_list: '', criteria_file: nil)
    @ticket = ticket
    @criteria_list = criteria_list
    @criteria_file = criteria_file
  end

  # @return [Array<String>]
  def criteria
    # find whitespace- and/or comma-separated group_ids xor issuers
    list_criteria = criteria_list.split(/,\s*|\s+/)
    file_criteria ||= if criteria_file
                        criteria_file.read.split(/,\s*|\s+/)
                      else
                        []
                      end
    @criteria ||= list_criteria.union(file_criteria)
  end

  # @return [Array<String>]
  def failures
    criteria.reject do |criterion|
      service_providers.find do |config|
        force_validation(config)
        config.issuer == criterion && config.errors.none?
      end
    end
  end

  # @return [Array<String>]
  def successes
    service_providers.map(&:issuer) - failures
  end

  def error_level
    return :error if successes.count.zero?
    return :warning if failures.count.positive?

    :success
  end

  def error_message
    return 'No valid ServiceProvider configs found' if successes.count.zero?

    'Some criteria were invalid. Please check the results.' if failures.count.positive?
  end

  # @return [String]
  def filename
    "config_extract_#{ticket.gsub(/\W/, '')}"
  end

  # @return [Array<Team>]
  def teams
    @teams ||= service_providers.map(&:team) || []
  end

  def to_json
    sp_data = service_providers.map do |sp|
      attributes = sp.attributes
      attributes['team_uuid'] = sp.team.uuid
      # The remote key is not portable between environments.
      attributes.delete 'remote_logo_key'
      attributes['logo'] = logo_filename_for(sp) if sp.logo_file.present?
      attributes
    end
    { teams: teams, service_providers: sp_data }.to_json
  end

  # @return [Array<ServiceProvider>]
  def service_providers
    @service_providers ||= ServiceProvider.joins(:team).where(issuer: criteria)
  end

  def valid?
    super
  end

  # @return [Array<Hash{Symbol=>String,ActiveStorage::Attached::One}>] For each service provider
  #   return a hash of the format `{attachment: ActiveStorage::Attached::One, filename: String }`
  def logos
    service_providers.map do |sp|
      next if sp.logo_file.blank?

      { filename: logo_filename_for(sp), attachment: sp.logo_file }
    end.compact
  end

  def logo_filename_for(sp)
    filename = sp.logo
    filename ||= sp.logo_file.blob.filename
    "#{sp.id}_#{filename}"
  end

  private

  # @return [nil, ActiveModel::Errors]
  def file_and_or_list
    return unless criteria.empty?

    errors.add(:criteria_file, 'or Criteria List are required.')
    errors.add(:criteria_list, 'or Criteria File are required.')
  end

  # This revalidates all service provider attributes except the issuer.
  # This gives us an advanced warning for attributes that we don't always check.
  # The issuer will always fail because it's already taken.
  def force_validation(config)
    config.attributes.each_key do |attr|
      config.public_send("#{attr}_will_change!")
    end
    config.valid?
  end
end
