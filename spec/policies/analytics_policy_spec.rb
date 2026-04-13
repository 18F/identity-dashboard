require 'rails_helper'

RSpec.describe AnalyticsPolicy, type: :policy do
  let(:user) { User.new }
  let(:logingov_admin) { create(:logingov_admin) }
  let(:logingov_readonly) { create(:logingov_readonly) }

  permissions :index? do
    context 'on production envs' do
      before do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
      end

      it 'denies users by default' do
        expect(AnalyticsPolicy).to_not permit(user)
      end

      it 'allows login.gov admin' do
        expect(AnalyticsPolicy).to permit(logingov_admin)
      end

      it 'denies login.gov readonly' do
        expect(AnalyticsPolicy).to_not permit(logingov_readonly)
      end
    end

    context 'on sandbox envs' do
      before do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(false)
      end

      it 'denies users by default' do
        expect(AnalyticsPolicy).to_not permit(user)
      end

      it 'denies login.gov staff' do
        expect(AnalyticsPolicy).to_not permit(logingov_admin)
        expect(AnalyticsPolicy).to_not permit(logingov_readonly)
      end
    end
  end
end
