class User < ApplicationRecord
  acts_as_paranoid

  has_paper_trail on: %i[create update destroy]

  devise :trackable, :timeoutable
  has_many :user_teams, dependent: :nullify
  has_many :teams, through: :user_teams
  has_many :service_providers, through: :teams
  has_many :security_events, dependent: :destroy
  has_many :user_roles
  has_many :roles, through: :user_roles

  validates :email, format: { with: Devise.email_regexp }

  validates_with UserValidator, on: :create

  scope :sorted, -> { order(email: :asc) }

  def scoped_teams
    if admin?
      Team.all
    else
      teams
    end
  end

  def scoped_service_providers
    (member_service_providers + service_providers).
      uniq.
      sort_by! { |sp| sp.friendly_name.downcase }
  end

  def user_deletion_history
    PaperTrail::Version.
      where(event: 'destroy', item_type: 'UserTeam').
      where("object ->>'user_id' = '?'", id)
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

  def user_deletion_history_report(limit: 5000)
    user_deletion_history.
      order(created_at: :desc).
      limit(limit).
      pluck(:object, :created_at, :whodunnit).
      map do |deleted_record, removed_at, whodunnit_id|
        deleted_record['removed_at'] = removed_at
        deleted_record['whodunnit_id'] = whodunnit_id
        user_deletion_report_item(deleted_record)
      end
  end

  def domain
    email.to_s.split('@')[1].to_s
  end

  def unconfirmed?
    last_sign_in_at.nil? && created_at < 14.days.ago
  end

  def has_role?(title)
    roles.include? Role.find_by(title:)
  end

  def admin?
    has_role? 'login_engineer'
  end

  def ic?
    has_role? 'ic'
  end

  def restricted_ic?
    has_role? 'restricted_ic'
  end

  private

  def member_service_providers
    ServiceProvider.where(user_id: id)
  end
end
