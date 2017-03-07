class UserGroup < ActiveRecord::Base
  validates :description, presence: true
  validates :name, presence: true, uniqueness: true
  has_many :service_providers

  def to_s
    name
  end
end
