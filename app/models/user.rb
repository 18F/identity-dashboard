class User < ApplicationRecord
  devise :trackable, :timeoutable
  has_many :user_groups
  has_many :groups, through: :user_groups
  has_many :service_providers, through: :groups

  validates :email, uniqueness: true

  scope :sorted, -> { order(email: :asc) }

  def scoped_groups
    if admin?
      Group.all
    else
      groups
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
