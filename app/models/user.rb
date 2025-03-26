class User < ApplicationRecord
  acts_as_paranoid

  has_paper_trail on: %i[create update destroy]

  devise :trackable, :timeoutable
  has_many :user_teams, dependent: :destroy
  has_many :teams, through: :user_teams
  has_many :service_providers, through: :teams
  has_many :security_events, dependent: :destroy

  validates :email, format: { with: Devise.email_regexp }

  validates_with UserValidator, on: :create

  scope :sorted, -> { order(email: :asc) }

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
      where(event: 'destroy', item_type: 'UserTeam').
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
    last_sign_in_at.nil? && created_at < 14.days.ago
  end

  def logingov_admin?
    # TODO: change this implementation
    admin_without_deprecation?
  end

  def primary_role
    return Role::LOGINGOV_ADMIN if logingov_admin?
    return user_teams.first.role if user_teams.first&.role.present?
    return Role.find_by(name: 'partner_readonly') if teams.any?

    Role.find_by(name: 'partner_admin')
  end

  def auth_token
    AuthToken.where(user: self).last || AuthToken.new_for_user(self)
  end

  module DeprecateAdmin
    def self.deprecator
      @deprecator ||= ActiveSupport::Deprecation.new("after we're fully migrated to RBAC", 'Portal')
    end

    def admin?
      super
    end

    alias admin_without_deprecation? admin?
    private :admin_without_deprecation?
  end

  include DeprecateAdmin
  deprecate admin?: 'use `logingov_admin?` instead', deprecator: DeprecateAdmin.deprecator
end
