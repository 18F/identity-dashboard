class ServiceProvider < ActiveRecord::Base
  belongs_to :user

  enum block_encryption: { 'aes256-cbc' => 1 }

  validates :issuer, presence: true, uniqueness: true

  def to_param
    issuer
  end

  def recently_approved?
    previous_changes.key?(:approved) && previous_changes[:approved].last == true
  end
end
