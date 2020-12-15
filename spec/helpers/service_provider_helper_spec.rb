require 'rails_helper'

describe ServiceProviderHelper do
  describe '#sp_logo_path' do
    context 'file name is present' do
      it 'returns the logo' do
        file = 'test.png'

        expect(sp_logo_path(file)).to match(
          /test.png/
        )
      end

      it 'returns a github raw file url string' do
        expect(sp_logo_path('test.png')).to eq('https://raw.githubusercontent.com/18F/identity-idp/master/app/assets/images/sp-logos/test.png')
      end
    end

    context 'file name is nil' do
      it 'returns generic logo' do
        file = nil

        expect(sp_logo_path(file)).to match(
          /generic.svg/
        )
      end
    end
  end

  describe '#sp_logo_preview_path' do
    context 'file name is present' do
      it 'returns a github preview url string' do
        expect(sp_logo_preview_path('test.svg')).to eq('https://github.com/18F/identity-idp/blob/master/app/assets/images/sp-logos/test.svg')
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
    let(:sp_config_protected_attributes) do
      %w[
        issuer
        id
        created_at
        updated_at
        user_id
        description
        approved
        active
        group_id
        identity_protocol
        production_issuer
        saml_client_cert
      ]
    end
    it 'returns the sp issuer in the yaml blurb' do
      expect(yamlized_sp(sp)).to include(sp.issuer)
    end

    it 'returns the sp configuration in the yaml blurb' do
      sp.attribute_names.each do |attribute_name|
        next if sp_config_protected_attributes.include?(attribute_name)
        expect(yamlized_sp(sp)).to include(attribute_name)
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
end
