class Application < ActiveRecord::Base
  belongs_to :user

  enum block_encryption: { 'aes256-cbc' => 1 }

  before_create :create_issuer

  def create_issuer
    self.issuer = SecureRandom.uuid unless issuer.present?
  end

  def to_param
    issuer
  end

  def recently_approved?
    previous_changes.key?(:approved) && previous_changes[:approved].last == true
  end
end
