class Organization < ActiveRecord::Base
  has_many :users

  def structured_name
    "#{self.agency}/#{self.department}/#{self.team}"
  end
end
