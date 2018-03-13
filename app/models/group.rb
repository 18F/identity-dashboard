class Group < ActiveRecord::Base
  has_many :service_providers
  has_many :user_groups
  has_many :users, through: :user_groups

  validates :name, presence: true, uniqueness: true

  def to_s
    name
  end
end
