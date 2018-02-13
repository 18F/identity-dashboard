class User < ActiveRecord::Base
  devise :trackable, :timeoutable
  has_many :user_groups
  has_many :groups, through: :user_groups
  has_many :service_providers, through: :groups

  scope :sorted, -> { order(email: :asc) }

  def scoped_groups
    if admin?
      Group.all
    else
      groups
    end
  end

  def scoped_service_providers
    (member_service_providers + service_providers).uniq
  end

  private

  def member_service_providers
    ServiceProvider.where(user_id: id)
  end

end
