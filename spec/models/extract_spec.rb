require 'rails_helper'

describe Extract do
  let(:user) { create(:user, :logingov_admin) }
  let(:issuer_file) { fixture_file_upload('issuers.txt', 'text/plain') }
  let(:team) { create(:team) }
  let(:sp1) { create(:service_provider, :ready_to_activate, team:) }
  let(:sp2) { create(:service_provider, :ready_to_activate) }

  describe 'Validations' do
    it { should validate_presence_of(:ticket) }

    it 'should not have errors when file_criteria are valid' do
      create(:service_provider, issuer: 'issuer:one', team:)

      with_file = build(:extract, {
        ticket: '1',
        criteria_file: issuer_file,
      })

      expect(with_file).to be_valid
      expect(with_file.errors).to be_empty
    end

    it 'should not have errors when list_criteria are valid' do
      with_list = build(:extract, {
        ticket: '0',
        criteria_list: "1,2, #{sp1.issuer}",
      })

      expect(with_list).to be_valid
      expect(with_list.errors).to be_empty
    end

    it 'should return errors when file and list criteria are excluded' do
      extract = build(:extract, {
        ticket: '0',
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
        criteria_list: sp1.issuer,
      })

      expect(extract.filename).to eq('config_extract_rmfr')
    end
  end

  describe '#failures' do
    it 'should return issuers not associated with an SP' do
      extract = build(:extract, {
        ticket: '0',
        criteria_list: 'fake:issuer:0 fake:issuer:1',
      })

      expect(extract.failures).to eq(['fake:issuer:0', 'fake:issuer:1'])
    end

    it 'should return issuers without SP even if others are successful' do
      extract = build(:extract, {
        ticket: '0',
        criteria_list: "#{sp2.issuer} fake:issuer:0",
      })

      expect(extract.failures).to eq(['fake:issuer:0'])
    end

    it 'should include issuers that will always be invalid' do
      sp2.redirect_uris = ['ftp:///']
      # Assertion: this is enough to indvalidate the record
      expect(sp2).to_not be_valid
      # Force it to save
      sp2.save!(validate: false)

      extract = build(:extract, {
        ticket: '0',
        criteria_list: "#{sp1.issuer} #{sp2.issuer}",
      })
      expect(extract.failures).to eq([sp2.issuer])
    end

    it 'should include issuers that validation problems we do not always check' do
      big_logo_upload = fixture_file_upload(File.join('..', 'big-logo.png'))
      sp1.logo = 'big-logo.png'
      sp1.logo_file.attach(big_logo_upload)
      # Assertion: this will not be valid unless we force it to save
      expect(sp1).to_not be_valid
      # Force it to save
      sp1.save!(validate: false)
      sp1.reload
      # Assertion: we don't revalidate this attribute by default
      expect(sp1).to be_valid

      extract = build(:extract, {
        ticket: '0',
        criteria_list: "#{sp1.issuer} #{sp2.issuer}",
      })
      expect(extract.failures).to eq([sp1.issuer])
    end
  end

  describe '#criteria' do
    it 'should return an empty array when there is no criteria uploaded' do
      extract = build(:extract, {
        ticket: '0',
        criteria_list: '',
      })

      expect(extract.criteria).to eq([])
    end

    it 'should return an array of the issuer strings in the criteria_file' do
      extract = build(:extract, {
        ticket: '0',
        criteria_file: issuer_file,
      })

      expect(extract.criteria).to eq(
        %w[issuer:one issuer:two issuer:three],
      )
    end

    it 'should concat file and list inputs into an array' do
      extract = build(:extract, {
        ticket: '0',
        criteria_list: 'list:issuer',
        criteria_file: issuer_file,
      })

      expect(extract.criteria).to eq(
        %w[list:issuer issuer:one issuer:two issuer:three],
      )
    end
  end

  describe '#teams' do
    it 'should return teams by SP issuer string' do
      extract = build(:extract, {
        ticket: '0',
        criteria_list: sp1.issuer,
      })

      expect(extract.teams).to eq([team])
    end
  end

  describe '#service_providers' do
    it 'should return existing SPs by issuer string' do
      extract = build(:extract, {
        ticket: '0',
        criteria_list: sp2.issuer,
      })

      expect(extract.service_providers).to eq([sp2])
    end
  end

  describe '#logos' do
    subject(:extract) do
      Extract.new(ticket: rand(1.1000), criteria_list: sp1.issuer)
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
      expected_contents = File.read(Rails.root.join(file_fixture_path, 'logo.svg').to_s)
      expect(extract.logos.first[:attachment].blob.download).to eq(expected_contents)
    end
  end
end
