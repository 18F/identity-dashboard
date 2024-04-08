require 'rails_helper'

describe UserPolicy do
  let(:admin) { create(:admin) }
  let(:ic_user) { create(:ic) }
  let(:restricted_user) { create(:restricted_ic) }
  let(:user_record) { build(:user) }

  permissions :manage_users? do
    it 'authorizes an admin' do
      expect(UserPolicy).to permit(admin, user_record)
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
      expect(UserPolicy).to permit(admin, user_record)
    end

    it 'gives access to an IC user' do
      expect(UserPolicy).to permit(ic_user, user_record)
    end

    it 'gives access to restricted ICs' do
      expect(UserPolicy).to permit(restricted_user, user_record)
    end
  end
end
