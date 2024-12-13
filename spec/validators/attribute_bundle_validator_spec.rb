require 'rails_helper'

class BundleTestRecord
  include ActiveModel::Validations
  attr_accessor :ial, :identity_protocol, :attribute_bundle

  validates_with AttributeBundleValidator
  def initialize
    @attribute_bundle = []
    @ial = nil
    @identity_protocol = nil
  end
end

RSpec.describe AttributeBundleValidator, type: 'model' do
  let(:test_model) { BundleTestRecord.new }
  let(:ial_1_bundle) { %w[email all_emails verified_at x509_subject x509_presented] }
  let(:ial_2_bundle) { %w[first_name last_name dob ssn address1 address2 city state zipcode phone] }
  let(:empty_bundle) { [] }

  it 'validates SAML at IAL 1 correctly' do
    saml_sp_ial1 = BundleTestRecord.new.tap do |model|
      model.identity_protocol = 'saml'
      model.ial = [1, '1'].sample
    end
    expect(saml_sp_ial1).to allow_value(empty_bundle).for(:attribute_bundle)
    expect(saml_sp_ial1).to allow_value(ial_1_bundle).for(:attribute_bundle)
    expect(saml_sp_ial1).to_not allow_value(ial_2_bundle).for(:attribute_bundle)
    expect(saml_sp_ial1).to_not allow_value(%w[gibberish]).for(:attribute_bundle)
  end

  it 'validates SAML at IAL 2 correctly' do
    saml_sp_ial2 = BundleTestRecord.new.tap do |model|
      model.identity_protocol = 'saml'
      model.ial = [2, '2'].sample
    end
    expect(saml_sp_ial2).to_not allow_value(empty_bundle).for(:attribute_bundle)
    expect(saml_sp_ial2).to allow_value(ial_1_bundle).for(:attribute_bundle)
    expect(saml_sp_ial2).to allow_value(ial_2_bundle).for(:attribute_bundle)
    expect(saml_sp_ial2).to_not allow_value(%w[gibberish]).for(:attribute_bundle)
  end

  it 'validates OIDC at IAL 1 correctly' do
    oidc_sp_ial1 = BundleTestRecord.new.tap do |model|
      model.identity_protocol = %w[openid_connect_private_key_jwt openid_connect_pkce].sample
      model.ial = [1, '1'].sample
    end
    expect(oidc_sp_ial1).to allow_value(empty_bundle).for(:attribute_bundle)
    expect(oidc_sp_ial1).to allow_value(ial_1_bundle).for(:attribute_bundle)
    expect(oidc_sp_ial1).to_not allow_value(ial_2_bundle).for(:attribute_bundle)
    expect(oidc_sp_ial1).to_not allow_value(%w[gibberish]).for(:attribute_bundle)
  end

  it 'validates OIDC at IAL 2 correctly' do
    oidc_sp_ial2 = BundleTestRecord.new.tap do |model|
      model.identity_protocol = 'openid_connect_private_key_jwt'
      model.ial = [2, '2'].sample
    end
    expect(oidc_sp_ial2).to allow_value(empty_bundle).for(:attribute_bundle)
    expect(oidc_sp_ial2).to allow_value(ial_1_bundle).for(:attribute_bundle)
    expect(oidc_sp_ial2).to allow_value(ial_2_bundle).for(:attribute_bundle)
    expect(oidc_sp_ial2).to_not allow_value(%w[gibberish]).for(:attribute_bundle)
  end
end
