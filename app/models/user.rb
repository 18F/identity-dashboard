class User < ApplicationRecord
  devise :trackable, :timeoutable
  has_many :user_teams, dependent: :nullify
  has_many :teams, through: :user_teams
  has_many :service_providers, through: :teams

  validates :email, uniqueness: true

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

  def domain
    email.to_s.split('@')[1].to_s
  end

  private

  def member_service_providers
    ServiceProvider.where(user_id: id)
  end
end
