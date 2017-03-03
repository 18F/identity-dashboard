class Organization < ActiveRecord::Base
  validates :agency_name, presence: true
  validates :department_name, presence: true
  validates :team_name, presence: true
  validates :agency_name, uniqueness: { scope: [:department_name, :team_name] }

  def to_s
    team_name
  end
end
