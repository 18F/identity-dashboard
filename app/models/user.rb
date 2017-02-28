class User < ActiveRecord::Base
  devise :trackable, :timeoutable, :omniauthable, omniauth_providers: [:saml]
  belongs_to :organization
  has_many :service_providers

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
    uid = auth_hash.uid
    where(uuid: uid).first_or_create do |user|
      user.email = info.email
      user.last_name = info.last_name
      user.first_name = info.first_name
      user.uuid = uid
    end.sync_with_auth_hash!(auth_hash)
  end

  def sync_with_auth_hash!(auth_hash)
    info = auth_hash.info
    uid = auth_hash.uid
    self.uuid = uid if uuid != uid
    self.first_name = info.first_name if first_name.blank? || first_name != info.first_name
    self.last_name = info.last_name if last_name.blank? || last_name != info.last_name
    save! if changed.any?
    self
  end

  def all_service_providers
    ServiceProvider.where("user_id = ? OR organization_id = ?", self.id, self.organization_id)
  end
end
