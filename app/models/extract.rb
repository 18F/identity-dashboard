class Extract # :nodoc:
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
      if extract_by_team?
        team.find do |config|
          config.id.to_s == criterion
        end
      else
        service_providers.find do |config|
         config.issuer == criterion
        end
      end
    end
  end

  # @return [String]
  def filename
    "#{Dir.tmpdir}/config_extract_#{ticket.gsub(/\W/, '')}"
  end

  # @return [Array<Hash{Team,Array<ServiceProvider>}>]
  #TODO: confirm we are rescuing from active record not found errors
  def teams
    @teams = []
    criteria.each do |crit|
      team_data = extract_by_team? ?
        Team.find(crit.to_i) : 
        Team.find(ServiceProvider.where(issuer: crit).select(:group_id))
      @team.push(team_data)
    end
  end

  def service_providers
    @service_providers = []
    criteria.each do |crit|
      service_providers_data = extract_by_team? ?
        ServiceProvider.where(group_id: crit) :
        ServiceProvider.where(issuer: crit)
      @service_providers.push(service_providers_data)
    end
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
