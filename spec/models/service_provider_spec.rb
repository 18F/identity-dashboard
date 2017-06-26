require 'rails_helper'

describe ServiceProvider do
  describe 'Associations' do
    it { should belong_to(:user) }
    it { should belong_to(:group) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:issuer) }
    it { should validate_presence_of(:issuer_department).on(:create) }
    it { should validate_presence_of(:issuer_app).on(:create) }
    it { should validate_presence_of(:agency) }

    it 'validate that issuer is formatted correctly' do
      valid_service_provider = build(
        :service_provider,
        issuer: 'urn:gov:gsa:SAML:2.0.profiles:sp:sso:GSA:app',
      )
      invalid_service_provider = build(
        :service_provider,
        issuer: 'i-dont-care-about-your-rules',
      )

      expect(valid_service_provider.valid?).to eq(true)
      expect(invalid_service_provider.valid?).to eq(false)
      expect(invalid_service_provider.errors).to include(:issuer)
      expect(invalid_service_provider.errors[:issuer]).to include(
        t('activerecord.errors.models.service_provider.attributes.issuer.invalid'),
      )
    end

    it 'does not validate issuer format on update' do
      service_provider = build(:service_provider, issuer: 'I am invalid :)')
      service_provider.save(validate: false)

      service_provider.friendly_name = 'Invalid issuer, but it\'s all good'

      expect(service_provider.valid?).to eq(true)
    end
  end

  let(:service_provider) { build(:service_provider) }

  describe 'Callbacks' do
    describe 'before_validation' do
      it 'builds an issuer from the issuer department and issuer app' do
        service_provider.issuer_department = 'ABC'
        service_provider.issuer_app = 'fantastic-app'
        service_provider.validate

        expect(service_provider.issuer).to include('ABC')
        expect(service_provider.issuer).to include('fantastic-app')
      end

      it 'does not build an issuer on update' do
        service_provider = create(:service_provider)

        service_provider.issuer_department = 'ABC'
        service_provider.issuer_app = 'fantastic-app'
        service_provider.validate

        expect(service_provider.issuer).not_to include('ABC')
        expect(service_provider.issuer).not_to include('fantastic-app')
      end
    end
  end

  it { should have_readonly_attribute(:issuer) }

  describe '#issuer_department' do
    it 'returns the value parsed from the issuer if no value has been set' do
      service_provider.issuer = 'urn:gov:gsa:SAML:2.0.profiles:sp:sso:ABC:app-name'
      expect(service_provider.issuer_department).to eq('ABC')
    end

    it 'returns nil if the issuer is invalid' do
      service_provider.issuer = 'invalid issuer'
      expect(service_provider.issuer_department).to eq(nil)
    end

    it 'returns the value that has been assigned to it' do
      service_provider.issuer_department = 'DEQ'
      expect(service_provider.issuer_department).to eq('DEQ')
    end
  end

  describe '#issuer_app' do
    it 'returns the value parsed from the issuer if no value has been set' do
      service_provider.issuer = 'urn:gov:gsa:SAML:2.0.profiles:sp:sso:ABC:app-name'
      expect(service_provider.issuer_app).to eq('app-name')
    end

    it 'returns nil if the issuer is invalid' do
      service_provider.issuer = 'invalid issuer'
      expect(service_provider.issuer_app).to eq(nil)
    end

    it 'returns the value that has been assigned to it' do
      service_provider.issuer_app = 'app-needing-login'
      expect(service_provider.issuer_app).to eq('app-needing-login')
    end
  end

  describe '#recently_approved?' do
    it 'detects when flag toggles to true' do
      expect(service_provider.recently_approved?).to eq false
      service_provider.approved = true
      service_provider.save!
      expect(service_provider.recently_approved?).to eq true
    end
  end
end
