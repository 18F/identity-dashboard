class Group < ApplicationRecord
  has_many :service_providers, dependent: :destroy
  has_many :user_groups, dependent: :destroy
  has_many :users, through: :user_groups

  validates :name, presence: true, uniqueness: true

  def to_s
    name
  end
end
