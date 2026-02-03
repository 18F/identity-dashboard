require 'rails_helper'
describe TeamHelper do
  let(:logingov_admin) { create(:user, :logingov_admin) }
  let(:logingov_readonly) { build(:user, :logingov_readonly) }
  let(:partner_admin) { build(:user, :partner_admin) }
  let(:partner_dev) { build(:user, :partner_developer) }
  let(:partner_readonly) { build(:user, :partner_readonly) }

  describe '#can_edit_teams?' do
    it "returns false if user doesn't have a team" do
      expect(can_edit_teams?(partner_admin)).to be_falsy
    end

    it 'returns true if user has a team' do
      partner_admin.teams = [create(:team)]

      expect(can_edit_teams?(partner_admin)).to be_truthy
    end

    it 'returns true if user is a login.gov admin' do
      expect(can_edit_teams?(logingov_admin)).to be_truthy
    end
  end
end
