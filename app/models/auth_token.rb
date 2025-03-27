class AuthToken < ApplicationRecord
  belongs_to :user

  has_paper_trail ignore: [:token, :encrypted_token]

  def self.new_for_user(user)
    # 54 chosen here because BCrypt seems to ignore anything longer
    self.build(user: user, token: SecureRandom.base64(54))
  end

  def token=(new_token)
    @token = new_token
    self.encrypted_token = password_digest(@token) if @token.present?
  end

  def ephemeral_token
    @token if new_record? || previously_new_record?
  end

  def valid_token?(token)
    Devise::Encryptor.compare(self.class, encrypted_token, token)
  end

  def self.stretches
    Devise.stretches
  end

  def self.pepper
    Devise.pepper
  end

  private

  # Hashes the password using bcrypt. Custom hash functions should override
  def password_digest(password)
    Devise::Encryptor.digest(self.class, password)
  end
end
