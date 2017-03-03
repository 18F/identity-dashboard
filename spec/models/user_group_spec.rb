require 'rails_helper'

describe UserGroup do
  describe 'Validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:description) }

    it 'validates uniqueness of name' do
      name = 'good name'
      create(:user_group, name: name)
      duplicate = build(:user_group, name: name)

      expect(duplicate).not_to be_valid
    end
  end
end
