# The Extract tool is used for migrating ServiceProvider data from `int`
# to `prod`.
class Extract
  include ActiveModel::Model

  attr_accessor :ticket, :search_by, :criteria_file, :criteria_list

  validates :ticket, presence: true
  validates :search_by, inclusion: { in: ['teams', 'issuers'] }
  validate :file_and_or_list

  # @param [String] ticket identifier used in file name
  # @param [String('teams', 'issuers')] search_by criteria to use
  # @param [String] criteria_list comma- and/or space-separated string
  # @param [File<text/plain>] criteria_file comma- and/or space-separated plaintext
  def initialize(ticket: '', search_by: 'teams', criteria_list: '', criteria_file: nil)
    @ticket = ticket
    @search_by = search_by
    @criteria_list = criteria_list
    @criteria_file = criteria_file
  end

  # @return [Array<String>]
  def criteria
    # find whitespace- and/or comma-separated group_ids xor issuers
    list_criteria = criteria_list.split(/,\s*|\s+/)
    file_criteria ||= criteria_file ?
      criteria_file.read.split(/,\s*|\s+/) :
      []
    @criteria ||= list_criteria.union(file_criteria)
  end

  # @return [Array<String>]
  def failures
    criteria.reject do |criterion|
      service_providers.find do |config|
        extract_by_team? ?
        config.group_id.to_s == criterion :
        config.issuer == criterion
      end
    end
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
      # This is not portable between environments.
      attributes.delete 'remote_logo_key'
      attributes
    end
    { teams: teams, service_providers: sp_data }.to_json
  end

  # @return [Array<ServiceProvider>]
  def service_providers
    @service_providers ||= extract_by_team? ?
      ServiceProvider.joins(:team).where(group_id: criteria) :
      ServiceProvider.joins(:team).where(issuer: criteria)
  end

  def valid?
    super
  end

  private

  # @return [Boolean]
  def extract_by_team?
    search_by == 'teams'
  end

  # @return [nil, ActiveModel::Errors]
  def file_and_or_list
    return unless criteria.empty?

    errors.add(:criteria_file, 'or Criteria List are required.')
    errors.add(:criteria_list, 'or Criteria File are required.')
  end
end
