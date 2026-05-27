require 'rails_helper'

RSpec.describe AnalyticPolicy, type: :policy do
  let(:user) { User.new }
  let(:logingov_admin) { create(:logingov_admin) }
  let(:logingov_readonly) { create(:logingov_readonly) }
  let(:partner_admin) { create(:user, :partner_admin) }
  let(:partner_developer) { create(:user, :partner_developer) }
  let(:partner_readonly) { create(:user, :partner_readonly) }

  permissions :index? do
    it 'denies when there is no user' do
      expect(described_class).to_not permit(nil)
    end

    it 'allows login.gov admin' do
      expect(described_class).to permit(logingov_admin)
    end

    it 'allows login.gov read-only' do
      expect(described_class).to permit(logingov_readonly)
    end

    it 'allows partner admin' do
      expect(described_class).to permit(partner_admin)
    end

    it 'allows partner developer' do
      expect(described_class).to permit(partner_developer)
    end

    it 'allows partner readonly' do
      expect(described_class).to permit(partner_readonly)
    end
  end
end
