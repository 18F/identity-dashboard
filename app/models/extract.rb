class Extract
  include ActiveModel::API
  include ActiveModel::Validations

  attr_accessor :ticket, :search_by, :criteria_file, :criteria_list

  validates :ticket, presence: true
  validates :search_by, inclusion: { in: ['teams', 'issuers'] }
  validate :file_and_or_list

  def initialize(ticket: '', search_by: 'teams', criteria_list: '', criteria_file: nil)
    @ticket = ticket
    @search_by = search_by
    @criteria_list = criteria_list
    @criteria_file = criteria_file
  end

  def criteria
    list_criteria = criteria_list.empty? ?
      [] :
      criteria_list.split(/,\s*|\s+/)
    file_criteria ||= criteria_file ?
      criteria_file.read.split(/,\s*|\s+/) :
      []
    @criteria ||= list_criteria.union(file_criteria)
  end

  def failures
    criteria.reject do |criterion|
      successes.find do |config|
        extract_by_team? ?
          config.group_id.to_s == criterion :
          config.issuer == criterion
      end
    end
  end

  def filename
    "#{Dir.tmpdir}/config_extract_#{ticket.gsub(/\W/, '')}"
  end

  def successes
    @successes ||= extract_by_team? ?
      ServiceProvider.where(group_id: criteria) :
      ServiceProvider.where(issuer: criteria)
  end

  def valid?
    super
  end

  private

  def extract_by_team?
    search_by == 'teams'
  end

  def file_and_or_list
    return unless criteria.empty?

      errors.add(:criteria_file, 'or Criteria List are required.')
      errors.add(:criteria_list, 'or Criteria File are required.')

  end
end
