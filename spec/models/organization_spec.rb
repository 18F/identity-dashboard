require 'rails_helper'

describe Organization do
  describe 'Validations' do
    it { should validate_presence_of(:agency_name) }
    it { should validate_presence_of(:department_name) }
    it { should validate_presence_of(:team_name) }

    it 'Validates uniqueness of the combined name fields' do
      create(:organization, agency_name: 'a', department_name: 'b', team_name: 'c')
      duplicate_org = build(:organization, agency_name: 'a', department_name: 'b', team_name: 'c')
      expect(duplicate_org).not_to be_valid
    end
  end
end
