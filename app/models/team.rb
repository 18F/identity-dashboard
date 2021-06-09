class Team < ApplicationRecord
  self.table_name = :groups

  has_paper_trail on: %i[create update destroy]

  belongs_to :agency

  has_many :service_providers, dependent: :nullify, foreign_key: 'group_id',
                               inverse_of: :team
  has_many :user_teams, foreign_key: 'group_id', inverse_of: :team
  has_many :users, dependent: :destroy, through: :user_teams

  validates :name, presence: true, uniqueness: true

  after_update :update_service_providers

  def to_s
    name
  end

  def user_deletion_history
    PaperTrail::Version.
      where(event: 'destroy', item_type: 'UserTeam').
      where("object ->>'group_id' = '?'", id)
  end

  def user_deletion_report_item(record)
    {
      user_id: record[0]['user_id'],
      user_email: User.find_by(id: record[0]['user_id'])&.email,
      team_id: record[0]['group_id'],
      team_name: Team.find_by(id: record[0]['group_id'])&.name,
      removed_at: record[1],
      whodunnit_id: record[2],
      whodunnit_email: User.find_by(id: record[2])&.email,
    }
  end

  def user_deletion_history_report(email = nil)
    user_deletion_history.
      order(created_at: :desc).
      limit(5000).
      pluck(:object, :created_at, :whodunnit).
      select { |record|
        email.nil? || User.find_by(id: record[0]['user_id'])&.email == email
      }.
      map { |record|
        user_deletion_report_item(record)
      }
  end

  def update_service_providers
    service_providers.each do |sp|
      sp.update(agency_id: agency.id) if agency
    end
  end
end
