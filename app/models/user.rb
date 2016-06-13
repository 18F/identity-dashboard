class User < ActiveRecord::Base
  devise :trackable, :timeoutable, :omniauthable, omniauth_providers: [:saml]
  has_many :applications

  before_create :create_uuid

  after_create :send_welcome

  def create_uuid
    self.uuid = SecureRandom.uuid unless uuid.present?
  end

  def send_welcome
    UserMailer.welcome_new_user(self).deliver_later
  end

  def name
    if first_name.present? || last_name.present?
      [first_name, last_name].join(' ')
    else
      email
    end
  end

  def to_param
    uuid
  end

  def self.from_omniauth(auth_hash)
    info = auth_hash.info
    new_uuid = auth_hash.uid
    new_email = info.email
    find_or_create_by(email: new_email) do |user|
      user.email = new_email
      user.last_name = info.last_name
      user.first_name = info.first_name
      user.uuid = new_uuid
    end.sync_with_auth_hash!(auth_hash)
  end

  def sync_with_auth_hash!(auth_hash)
    info = auth_hash.info
    new_uuid = auth_hash.uid
    self.uuid = new_uuid if uuid != new_uuid
    self.first_name = info.first_name if first_name.blank? || first_name != info.first_name
    self.last_name = info.last_name if last_name.blank? || last_name != info.last_name
    save! if changed.any?
    self
  end
end
