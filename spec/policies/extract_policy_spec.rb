require 'rails_helper'

describe ExtractPolicy do
  let(:user) { build(:user) }
  let(:logingov_admin) { create(:team_membership, :logingov_admin).user }
  let(:extract) do
    build(:extract, {
      ticket: '0',
      search_by: 'issuers',
      criteria_list: 'fake:issuer',
    })
  end

  permissions :index? do
    it 'allows login.gov admins' do
      expect(ExtractPolicy).to permit(logingov_admin)
    end

    it 'does not allow non-admins' do
      expect(ExtractPolicy).to_not permit(user)
    end
  end

  permissions :create? do
    it 'allows login.gov admins' do
      expect(ExtractPolicy).to permit(logingov_admin)
    end

    it 'does not allow non-admins' do
      expect(ExtractPolicy).to_not permit(user)
    end
  end
end
