require 'rails_helper'

describe Extract do
  let(:user) { create(:user, :logingov_admin) }

  describe 'Validations' do
    it { should validate_presence_of(:ticket) }

    it { should validate_inclusion_of(:search_by).in_array(%w[teams issuers]) }

    it 'should validate that file or list criteria are included' do
      test_extract = build(:extract, {
        ticket: '1',
        search_by:'teams',
        criteria_list: '',
      } )

      expect(test_extract).to_not be_valid
    end
  end

  describe '#file_criteria' do
  end

  describe '#list_criteria' do
  end
end
