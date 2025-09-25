require 'rails_helper'

describe ExtractPolicy do
  let(:user) { build(:user) }
  let(:admin) { build(:user, :logingov_admin) }
  let(:extract) do
    build(:extract, {
      ticket: '0',
      search_by: 'issuers',
      criteria_list: 'fake:issuer',
    } )
  end

  permissions :index? do
    it 'allows admins' do
      expect(ExtractPolicy).to permit(admin)
    end

    it 'does not allow non-admins' do
      expect(ExtractPolicy).to_not permit(user)
    end
  end

  permissions :create? do
    it 'allows admins' do
      expect(ExtractPolicy).to permit(admin)
    end

    it 'does not allow non-admins' do
      expect(ExtractPolicy).to_not permit(user)
    end
  end
end
