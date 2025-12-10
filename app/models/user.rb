# User is an individual who can be added to a Team (with a Role) and
# can interact with the Portal.
class User < ApplicationRecord
  acts_as_paranoid

  has_paper_trail on: %i[create update destroy]

  devise :trackable, :timeoutable
  has_many :team_memberships, dependent: :destroy
  has_many :teams, through: :team_memberships
  has_many :service_providers, through: :teams
  has_many :security_events, dependent: :destroy

  validates :email, presence: true, format: { with: Devise.email_regexp }

  validates_with UserValidator, on: :create

  scope :sorted, -> { order(email: :asc) }

  ALLOWLISTED_DOMAINS = %w[.mil .gov .fed.us].freeze

  def scoped_teams
    if logingov_admin?
      Team.all
    else
      teams
    end
  end

  def scoped_service_providers(scope: nil)
    scope ||= ServiceProvider.all
    scope.where(id: service_providers).order('lower(friendly_name)')
  end

  def user_deletion_history
    PaperTrail::Version.
      where(event: 'destroy', item_type: TeamAuditEvent::TEAM_MEMBERSHIP_EVENT_TYPES).
      where("object ->>'user_id' = CAST(? as varchar)", id)
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
    # This means "created before 2 weeks ago"
    # "the date `created_at` is less than the date `14.days.ago`"
    last_sign_in_at.nil? && created_at < 14.days.ago
  end

  def logingov_admin?
    TeamMembership.find_by(user: self, team: Team.internal_team, role: Role::LOGINGOV_ADMIN)
  end

  def logingov_readonly?
    TeamMembership.find_by(user: self, team: Team.internal_team, role: Role::LOGINGOV_READONLY)
  end

  def logingov_staff?
    logingov_admin? || logingov_readonly?
  end

  def gov_partner?
    ALLOWLISTED_DOMAINS.any? { |domain| self.email.end_with? domain }
  end

  def primary_role
    return Role::LOGINGOV_ADMIN if logingov_admin?
    return Role::LOGINGOV_READONLY if logingov_readonly?
    return team_memberships.first.role if team_memberships.first&.role.present?

    return Role.find_by(name: 'partner_readonly') if teams.any?

    Role.find_by(name: 'partner_admin')
  end

  def readonly_role?
    logingov_readonly? || primary_role.name == 'partner_readonly'
  end

  def auth_token
    AuthToken.for(self)
  end

  def grant_team_membership(team, role_name)
    membership = team_memberships.find_by(group_id: team.id)
    return unless membership.present? && membership.role.blank?

    membership.role = Role.find_by(name: role_name)
    membership.save
  end
end
