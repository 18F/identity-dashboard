class UserGroup < ActiveRecord::Base
  validates :description, presence: true
  validates :name, presence: true, uniqueness: true

  def to_s
    name
  end
end
