class UserGroup < ActiveRecord::Base
  has_many :users

  validates :description, presence: true
  validates :name, presence: true, uniqueness: true
  has_many :service_providers

  def to_s
    name
  end
end
