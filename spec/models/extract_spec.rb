require 'rails_helper'

describe Extract do
  let(:user) { create(:user, :logingov_admin) }
  let(:issuer_file) { fixture_file_upload('issuers.txt', 'text/plain') }
  let(:team) { create(:team) }
  let(:sp1) { create(:service_provider, :ready_to_activate, team:) }
  let(:sp2) { create(:service_provider, :ready_to_activate) }

  describe 'Validations' do
    it { should validate_presence_of(:ticket) }

    it { should validate_inclusion_of(:search_by).in_array(%w[teams issuers]) }

    it 'should not have errors when file_criteria are valid' do
      with_file = build(:extract, {
        ticket: '1',
        search_by: 'issuers',
        criteria_file: issuer_file,
      })

      expect(with_file).to be_valid
      expect(with_file.errors).to be_empty
    end

    it 'should not have errors when list_criteria are valid' do
      with_list = build(:extract, {
        ticket: '0',
        search_by: 'teams',
        criteria_list: '1 ,2',
      })

      expect(with_list).to be_valid
      expect(with_list.errors).to be_empty
    end

    it 'should return errors when file and list criteria are excluded' do
      extract = build(:extract, {
        ticket: '0',
        search_by: 'teams',
        criteria_list: '',
      })

      expect(extract).to_not be_valid
      expect(extract.errors).to include(:criteria_list, :criteria_file)
    end
  end

  describe '#filename' do
    it 'should sanitize ticket string' do
      extract = build(:extract, {
        ticket: 'rm -fr /',
        search_by: 'issuers',
        criteria_list: sp1.issuer,
      })

      expect(extract.filename).to eq('config_extract_rmfr')
    end
  end

  describe '#failures' do
    it 'should return team IDs missing a team or SP' do
      extract = build(:extract, {
        ticket: '0',
        search_by: 'teams',
        criteria_list: '0, 9999999',
      })

      expect(extract.failures).to eq(['0', '9999999'])
    end

    it 'should return team IDs missing SP even if others are successful' do
      extract = build(:extract, {
        ticket: '0',
        search_by: 'teams',
        criteria_list: "#{sp1.group_id} 0",
      })

      expect(extract.failures).to eq(['0'])
    end

    it 'should return issuers not associated with an SP' do
      extract = build(:extract, {
        ticket: '0',
        search_by: 'issuers',
        criteria_list: 'fake:issuer:0 fake:issuer:1',
      })

      expect(extract.failures).to eq(['fake:issuer:0', 'fake:issuer:1'])
    end

    it 'should return issuers without SP even if others are successful' do
      extract = build(:extract, {
        ticket: '0',
        search_by: 'issuers',
        criteria_list: "#{sp2.issuer} fake:issuer:0",
      })

      expect(extract.failures).to eq(['fake:issuer:0'])
    end
  end

  describe '#criteria' do
    it 'should return an empty array when there is no criteria uploaded' do
      extract = build(:extract, {
        ticket: '0',
        search_by: 'teams',
        criteria_list: '',
      })

      expect(extract.criteria).to eq([])
    end

    it 'should return an array of the issuer strings in the criteria_file' do
      extract = build(:extract, {
        ticket: '0',
        search_by: 'issuers',
        criteria_file: issuer_file,
      })

      expect(extract.criteria).to eq(
        %w[issuer:one issuer:two issuer:three],
      )
    end

    it 'should return an array of the team ids in the criteria_list' do
      extract = build(:extract, {
        ticket: '0',
        search_by: 'teams',
        criteria_list: '1,  2 3
        4',
      })

      expect(extract.criteria).to eq(%w[1 2 3 4])
    end

    it 'should concat file and list inputs into an array' do
      extract = build(:extract, {
        ticket: '0',
        search_by: 'issuers',
        criteria_list: 'list:issuer',
        criteria_file: issuer_file,
      })

      expect(extract.criteria).to eq(
        %w[list:issuer issuer:one issuer:two issuer:three],
      )
    end
  end

  describe '#teams' do
    it 'should return existing teams by team ID' do
      extract = build(:extract, {
        ticket: '0',
        search_by: 'teams',
        criteria_list: sp1.group_id.to_s,
      })

      expect(extract.teams).to eq([team])
    end

    it 'should return teams by SP issuer string' do
      extract = build(:extract, {
        ticket: '0',
        search_by: 'issuers',
        criteria_list: sp1.issuer,
      })

      expect(extract.teams).to eq([team])
    end
  end

  describe '#service_providers' do
    it 'should return existing SPs by team ID' do
      extract = build(:extract, {
        ticket: '0',
        search_by: 'teams',
        criteria_list: sp1.group_id.to_s,
      })

      expect(extract.service_providers).to eq([sp1])
    end

    it 'should return existing SPs by issuer string' do
      extract = build(:extract, {
        ticket: '0',
        search_by: 'issuers',
        criteria_list: sp2.issuer,
      })

      expect(extract.service_providers).to eq([sp2])
    end
  end

  describe '#logos' do
    subject(:extract) do
      Extract.new(ticket: rand(1.1000), search_by: 'issuers', criteria_list: sp1.issuer)
    end

    it 'is empty if the service provider has no logo' do
      expect(extract.logos).to be_empty
    end

    it 'contains a logo and prefixed filename' do
      sp1.logo_file = fixture_file_upload('logo.svg')
      sp1.logo = 'logo.svg'
      sp1.save!
      expect(extract.logos.count).to be 1
      expect(extract.logos.first[:filename]).to eq("#{sp1.id}_logo.svg")
      expected_contents = File.read(File.join(Rails.root, file_fixture_path, 'logo.svg'))
      expect(extract.logos.first[:attachment].blob.download).to eq(expected_contents)
    end
  end
end
