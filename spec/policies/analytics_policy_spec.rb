require 'rails_helper'

RSpec.describe AnalyticsPolicy, type: :policy do
  let(:user) { User.new }
  let(:logingov_admin) { create(:logingov_admin) }

  permissions :index? do
    context 'on production envs' do
      before do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
      end

      it 'denies users by default' do
        expect(AnalyticsPolicy).to_not permit(user)
      end

      it 'allows login.gov admins' do
        expect(AnalyticsPolicy).to permit(logingov_admin)
      end
    end

    context 'on sandbox envs' do
      before do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(false)
      end

      it 'denies users by default' do
        expect(AnalyticsPolicy).to_not permit(user)
      end

      it 'denies login.gov admins' do
        expect(AnalyticsPolicy).to_not permit(logingov_admin)
      end
    end
  end
end
