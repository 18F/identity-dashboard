class UserGroup < ActiveRecord::Base
  has_many :service_providers
  has_many :users

  validates :description, presence: true
  validates :name, presence: true, uniqueness: true

  def to_s
    name
  end
end
