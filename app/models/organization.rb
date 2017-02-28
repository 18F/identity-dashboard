class Organization < ActiveRecord::Base
  has_many :users
  has_many :service_providers

  def structured_name
    "#{self.department}/#{self.agency}/#{self.team}"
  end
end
