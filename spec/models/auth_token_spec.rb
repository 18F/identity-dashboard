require 'rails_helper'

RSpec.describe AuthToken, type: :model do
  subject(:new_token_record) { described_class.new_for_user(logingov_admin) }

  let(:logingov_admin) { create(:logingov_admin) }

  describe '.new_for_user' do
    it 'assigns the user' do
      expect(new_token_record.user).to be logingov_admin
    end

    it 'creates an ephemeral token 72 characters long' do
      expect(new_token_record.ephemeral_token.length).to be 72
    end

    it 'encrypts the token' do
      expect(new_token_record.encrypted_token).to_not be_blank
      expect(new_token_record.encrypted_token).to_not eq new_token_record.ephemeral_token
      expect(new_token_record).to be_valid_token new_token_record.ephemeral_token
    end
  end

  describe '.for' do
    it 'returns `nil` for unauthorized users' do
      user = create(:user)
      AuthToken.new_for_user(user).save!
      expect(AuthToken.for(user)).to be_nil
    end

    it 'works for admins' do
      logingov_admin = create(:user, :logingov_admin)
      token = AuthToken.new_for_user(logingov_admin)
      ephemeral_token = token.ephemeral_token
      token.save!

      expect(AuthToken.for(logingov_admin).encrypted_token).to eq(token.encrypted_token)
      expect(AuthToken.for(logingov_admin)).to be_valid(ephemeral_token)
    end
  end

  describe '#valid_token' do
    it 'is not true for a different token' do
      different_token = SecureRandom.base64(54)
      expect(new_token_record).to_not be_valid_token different_token
    end

    it { expect(new_token_record).to be_valid_token new_token_record.ephemeral_token }
  end

  describe '#token=' do
    it 'updates the encrypted token' do
      new_value = SecureRandom.base64(54)
      expect(new_token_record).to_not be_valid_token new_value

      original_encrypted_token = new_token_record.encrypted_token
      new_token_record.token = new_value
      expect(new_token_record.encrypted_token).to_not eq new_value
      expect(new_token_record.encrypted_token).to_not eq original_encrypted_token
      expect(new_token_record).to be_valid_token new_value
    end

    it 'does nothing with a blank value' do
      original_encrypted_token = new_token_record.encrypted_token
      new_token_record.token = ''
      expect(new_token_record.encrypted_token).to eq original_encrypted_token
    end
  end

  describe '#ephemeral_token' do
    it 'is not available when loading from the database' do
      new_token_record.save!
      token_record_from_db = AuthToken.last
      expect(token_record_from_db.ephemeral_token).to be_nil
    end
  end
end
