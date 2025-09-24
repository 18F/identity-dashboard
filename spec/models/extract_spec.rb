require 'rails_helper'

describe Extract do
  let(:user) { create(:user, :logingov_admin) }
  let(:issuer_file) { fixture_file_upload('issuers.txt', 'text/plain') }

  describe 'Validations' do
    it { should validate_presence_of(:ticket) }

    it { should validate_inclusion_of(:search_by).in_array(%w[teams issuers]) }

    it 'should validate that file or list criteria are included' do
      with_list = build(:extract, {
        ticket: '0',
        search_by: 'teams',
        criteria_list: '1 ,2',
      } )
      with_file = build(:extract, {
        ticket: '1',
        search_by: 'issuers',
        criteria_file: issuer_file,
      } )

      expect(with_list).to be_valid
      expect(with_file).to be_valid
      expect(with_list.errors).to be_empty
      expect(with_file.errors).to be_empty
    end

    it 'should add errors when file and list criteria are excluded' do
      test_extract = build(:extract, {
        ticket: '0',
        search_by: 'teams',
        criteria_list: '',
      } )

      expect(test_extract).to_not be_valid
      expect(test_extract.errors).to include(:criteria_list, :criteria_file)
    end
  end

  describe '#file_criteria' do
    it 'should return an empty array when there is no file uploaded' do
      extract = build(:extract, {
        ticket: '0',
        search_by: 'teams',
        criteria_list: '1',
      } )

      expect(extract.file_criteria).to eq([])
    end

    it 'should return an array of the issuer strings in the criteria_file' do
      extract = build(:extract, {
        ticket: '0',
        search_by: 'issuers',
        criteria_file: issuer_file,
      } )

      expect(extract.file_criteria).to eq(
        ['issuer:one', 'issuer:two', 'issuer:three'],
      )
    end
  end

  describe '#list_criteria' do
    it 'should return an empty array when there is no file uploaded' do
      extract = Extract.new(
        ticket: '0',
        search_by: 'issuers',
        criteria_file: issuer_file,
      )

      expect(extract.list_criteria).to eq([])
    end

    it 'should return an array of the team ids in the criteria_list' do
      extract = Extract.new(
        ticket: '0',
        search_by: 'teams',
        criteria_list: '1,  2 3
        4',
      )

      expect(extract.list_criteria).to eq(%w[1 2 3 4])
    end
  end
end
