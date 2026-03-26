require 'rails_helper'

RSpec.describe AnalyticPolicy, type: :policy do
  let(:user) { User.new }
  let(:logingov_admin) { create(:logingov_admin) }
  let(:logingov_readonly) { create(:logingov_readonly) }

  permissions :index? do
    context 'on production envs' do
      before do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
      end

      it 'denies users by default' do
        expect(described_class).to_not permit(user)
      end

      it 'allows login.gov staff' do
        expect(described_class).to permit(logingov_admin)
        expect(described_class).to permit(logingov_readonly)
      end
    end

    context 'on sandbox envs' do
      before do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(false)
      end

      it 'denies users by default' do
        expect(described_class).to_not permit(user)
      end

      it 'allows login.gov admin' do
        expect(described_class).to permit(logingov_admin)
      end

      it 'denies login.gov read-only' do
        expect(described_class).to_not permit(logingov_readonly)
      end
    end
  end
end
