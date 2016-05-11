class User < ActiveRecord::Base
  devise :trackable, :omniauthable, omniauth_providers: [:saml]
  has_many :applications

  before_create :create_uuid

  def create_uuid
    unless self.uuid.present?
      self.uuid = SecureRandom.uuid
    end
  end

  def name
    if first_name.present? || last_name.present?
      [first_name, last_name].join(' ')
    else
      email
    end
  end

  def admin?
    false  # TODO roles
  end

  def to_param
    uuid
  end
end
