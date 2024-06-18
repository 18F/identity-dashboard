class ServiceProviderPolicy < BasePolicy
  attr_reader :user, :record

  def all?
    admin?
  end

  def deleted?
    admin?
  end

  def create?
    true
  end

  def index?
    true
  end

  def member_or_admin?
    owner? || admin? || member?
  end

  def new?
    true
  end

  private

  def owner?
    record.user == user
  end

  def member?
    team = record.team
    team.present? && user.teams.include?(team)
  end
end
