require 'rails_helper'

describe ServiceProviderHelper do
  describe '#sp_logo_path' do
    context 'file name is present' do
      it 'returns the logo' do
        file = 'test.png'

        expect(sp_logo_path(file)).to match(
          /test.png/,
        )
      end

      it 'returns a github raw file url string' do
        expect(sp_logo_path('test.png')).to eq('https://raw.githubusercontent.com/18F/identity-idp/main/app/assets/images/sp-logos/test.png')
      end
    end

    context 'file name is nil' do
      it 'returns generic logo' do
        file = nil

        expect(sp_logo_path(file)).to match(
          /generic.svg/,
        )
      end
    end
  end

  describe '#sp_logo_preview_path' do
    context 'file name is present' do
      it 'returns a github preview url string' do
        expect(sp_logo_preview_path('test.svg')).to eq('https://github.com/18F/identity-idp/blob/main/app/assets/images/sp-logos/test.svg')
      end
    end
  end

  describe '#sp_logo' do
    context 'file is svg' do
      it 'returns a link' do
        file = 'test.svg'

        expect(sp_logo(file)).to eq(link_to(file, sp_logo_preview_path(file)))
      end
    end

    context 'file is png' do
      it 'returns an image tag' do
        file = 'test.png'

        expect(sp_logo(file)).to eq(image_tag(sp_logo_path(file)))
      end
    end

    context 'file is nil' do
      it 'returns a link to generic.svg' do
        file = nil
        default = 'generic.svg'

        expect(sp_logo(file)).to eq(link_to(default, sp_logo_preview_path(default)))
      end
    end
  end

  describe '#yamlized_sp' do
    let(:sp) { create(:service_provider) }
    
    it 'returns the sp issuer in the yaml blurb' do
      expect(yamlized_sp(sp)).to include(sp.issuer)
    end
  end

  describe '#config_hash' do
    let(:saml_sp) { create(:service_provider, :saml) }
    let(:oidc_pkce_sp) {create(:service_provider, :with_oidc_pkce )}
    let(:oidc_jwt_sp) {create(:service_provider, :with_oidc_jwt )}
    let(:sp_config_saml_attributes) do 
      %w[
        agency_id
        friendly_name
        agency
        logo
        certs
        return_to_sp_url
        redirect_uris
        acs_url
        assertion_consumer_logout_service_url
        block_encryption
        sp_initiated_login_url
        return_to_sp_url
        failure_to_proof_url
        ial
        attribute_bundle
        restrict_to_deploy_env
        protocol
        help_text
        app_id
        launch_date
        iaa
        iaa_start_date
        iaa_end_date
      ]
    end
    let(:sp_config_oidc_attributes) do
      %w[
        agency_id
        friendly_name
        agency
        logo
        certs
        return_to_sp_url
        redirect_uris
        return_to_sp_url
        failure_to_proof_url
        ial
        attribute_bundle
        restrict_to_deploy_env
        protocol
        help_text
        app_id
        launch_date
        iaa
        iaa_start_date
        iaa_end_date
      ]
    end
    it 'returns a properly formatted yaml blurb for SAML' do
      sp_config_saml_attributes.each do |attribute_name|
        expect(config_hash(saml_sp)).to include(attribute_name)
      end
    end
    it 'returns a properly formatted yaml blurb for OIDC pkce' do
      sp_config_oidc_attributes.each do |attribute_name|
        expect(config_hash(oidc_pkce_sp)).to include(attribute_name)
      end
    end
    it 'returns a properly formatted yaml blurb for OIDC jwt' do
      sp_config_oidc_attributes.each do |attribute_name|
        expect(config_hash(oidc_jwt_sp)).to include(attribute_name)
      end
    end
  end

  describe '#sp_active_img_alt' do
    it 'returns alt tag indicating active service provider' do
      expect(sp_active_img_alt(true)).to eq('Active service provider')
    end

    it 'returns alt tag indicating inactive service provider' do
      expect(sp_active_img_alt(false)).to eq('Inactive service provider')
    end
  end

  describe '#sp_allow_prompt_login_img_alt' do
    it 'returns alt tag indicating prompt=login enabled' do
      expect(sp_allow_prompt_login_img_alt(true)).to eq('prompt=login enabled')
    end

    it 'returns alt tag indicating prompt=login disabled' do
      expect(sp_allow_prompt_login_img_alt(false)).to eq('prompt=login disabled')
    end
  end

  describe '#sp_attribute_bundle' do
    it 'returns a comma separated string of alphabetized attributes by default' do
      sp = instance_double(ServiceProvider, attribute_bundle: %w[first_name email])
      expect(sp_attribute_bundle(sp)).to eq('email, first_name')
    end

    it 'returns an empty string if attribute_bundle is nil' do
      sp = instance_double(ServiceProvider, attribute_bundle: nil)
      expect(sp_attribute_bundle(sp)).to eq('')
    end

    it 'returns an empty string if attribute_bundle is empty' do
      sp = instance_double(ServiceProvider, attribute_bundle: [])
      expect(sp_attribute_bundle(sp)).to eq('')
    end

    it 'filters out invalid attributes' do
      sp = instance_double(ServiceProvider, attribute_bundle: %w[first_name middle_name email])
      expect(sp_attribute_bundle(sp)).to eq('email, first_name')
    end
  end
end
