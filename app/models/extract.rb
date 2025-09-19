class Extract
  include ActiveModel::API
  include ActiveModel::Validations

  attr_accessor :ticket, :team_search, :criteria_file, :extract_list, :successes, :failures

  # do activeRecord validation syntax stuff here
  validates :ticket, presence: true
  validates :team_search, inclusion: { in: [true, false] }
end
