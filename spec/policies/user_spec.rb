require 'rails_helper'

describe UserPolicy do
  let(:login_engineer) { build(:admin) }
  let(:ic_user) { build(:ic) }
  let(:restricted_user) { build(:user) }
  let(:user_record) { build(:user) }

  permissions :login_engineer? do
    it 'authorizes a Login engineer' do
      expect(UserPolicy).to permit(login_engineer, user_record)
    end
    it 'does not authorize an IC user' do
      expect(UserPolicy).to_not permit(ic_user, user_record)
    end
    it 'does not authorize other users' do
      expect(UserPolicy).to_not permit(restricted_user, user_record)
    end
  end

  permissions :none? do
    it 'gives access to Login engineers' do
      expect(UserPolicy).to permit(login_engineer, user_record)
    end

    it 'gives access to an IC user' do
      expect(UserPolicy).to permit(ic_user, user_record)
    end

    it 'gives access to restricted ICs' do
      expect(UserPolicy).to permit(restricted_user, user_record)
    end
  end
end
