class Team < ApplicationRecord
  self.table_name = :groups

  has_paper_trail on: %i[create update destroy]

  belongs_to :agency

  has_many :service_providers, dependent: :nullify, foreign_key: 'group_id',
                               inverse_of: :team
  has_many :user_teams, foreign_key: 'group_id', inverse_of: :team, dependent: :destroy
  has_many :users, through: :user_teams, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  after_update :update_service_providers

  def to_s
    name
  end

  def user_deletion_history
    PaperTrail::Version.
      where(event: 'destroy', item_type: 'UserTeam').
      where("object ->>'group_id' = CAST(? as varchar)", id)
  end

  def user_deletion_report_item(deleted_record)
    {
      user_id: deleted_record['user_id'],
      user_email: User.find_by(id: deleted_record['user_id'])&.email,
      team_id: deleted_record['group_id'],
      team_name: Team.find_by(id: deleted_record['group_id'])&.name,
      removed_at: deleted_record['removed_at'],
      whodunnit_id: deleted_record['whodunnit_id'],
      whodunnit_email: User.find_by(id: deleted_record['whodunnit_id'])&.email,
    }
  end

  def user_deletion_history_report(email: nil, limit: 5000)
    user_deletion_history.
      order(created_at: :desc).
      limit(limit).
      pluck(:object, :created_at, :whodunnit).
      select do |object, _, _|
        email.nil? || User.find_by(id: object['user_id'])&.email == email
      end.
      map do |deleted_record, removed_at, whodunnit_id|
        deleted_record['removed_at'] = removed_at
        deleted_record['whodunnit_id'] = whodunnit_id
        user_deletion_report_item(deleted_record)
      end
  end

  def update_service_providers
    service_providers.each do |sp|
      sp.update(agency_id: agency.id) if agency
    end
  end

  # Every team should have a partner admin, but regularly we'll want to create a team before we know
  # who the partner admin should be.
  def missing_a_partner_admin?
    UserTeam.where(team: self).none? do |membership|
      # Every membership must have a valid user.
      # Until we clean up the data and add a db constraint, we should check that the user is not nil
      membership.role_name == 'partner_admin' && membership.user
    end
  end
end
