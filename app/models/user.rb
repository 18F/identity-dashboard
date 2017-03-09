class User < ActiveRecord::Base
  devise :trackable, :timeoutable, :omniauthable, omniauth_providers: [:saml]
  has_many :service_providers
  belongs_to :user_group

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
    self.first_name = first_name_from(info)
    self.last_name = last_name_from(info)
    save! if changed.any?
    self
  end

  def scoped_service_providers
    (
      service_providers +
      member_service_providers
    ).uniq
  end

  private

  def member_service_providers
    user_group ? user_group.service_providers : []
  end

  def first_name_from(info)
    info.first_name if first_name.blank? || first_name != info.first_name
  end

  def last_name_from(info)
    info.last_name if last_name.blank? || last_name != info.last_name
  end
end
