class Extract
  include ActiveModel::API
  include ActiveModel::Validations

  attr_accessor :ticket, :search_by, :criteria_file, :file_criteria,
    :criteria_list, :list_criteria, :successes, :failures

  validates :ticket, presence: true
  validates :search_by, inclusion: { in: ['teams', 'issuers'] }
  validate :file_and_or_list

  def initialize(args)
    @ticket = args[:ticket] || ''
    @search_by = args[:search_by] || 'teams'
    @criteria_list = args[:criteria_list] || ''
    @criteria_file = args[:criteria_file]
    @file_criteria = criteria_file ?
      criteria_file.read.split(/,\s*|\s+/) :
      []
    @list_criteria = criteria_list.empty? ?
      [] :
      criteria_list.split(/,\s*|\s+/)
  end

  def valid?
    super
  end

  def file_and_or_list
    if @criteria_list.empty? && @file_criteria.empty?
      errors.add(:criteria_file, 'or Criteria List are required.')
      errors.add(:criteria_list, 'or Criteria File are required.')
      return false
    end
    true
  end
end
