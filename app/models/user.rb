class User < ActiveRecord::Base
  has_many :applications

  before_create :create_uuid

  def create_uuid
    unless self.uuid
      self.uuid = SecureRandom.uuid
    end
  end
end
