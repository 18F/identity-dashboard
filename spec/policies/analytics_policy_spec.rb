require 'rails_helper'

RSpec.describe AnalyticsPolicy, type: :policy do
  let(:user) { User.new }
  let(:logingov_admin) { build(:logingov_admin) }

  permissions :show? do
    it 'denies users by default' do
      expect(AnalyticsPolicy).not_to permit(user)
    end

    it 'allows login.gov admins' do
      expect(AnalyticsPolicy).to permit(logingov_admin)
    end
  end
end
