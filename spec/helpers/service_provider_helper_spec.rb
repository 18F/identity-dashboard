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
    let(:oidc_pkce_sp) { create(:service_provider, :with_oidc_pkce) }
    let(:oidc_jwt_sp) { create(:service_provider, :with_oidc_jwt) }
    let(:saml_sp_ial_2) { create(:service_provider, :saml, :with_ial_2) }
    let(:oidc_jwt_sp_2) { create(:service_provider, :with_oidc_jwt, :with_ial_2) }
    let(:saml_without_requested_response) do
      create(:service_provider, :saml, :without_signed_response_message_requested)
    end
    let(:saml_email_id_format) { create(:service_provider, :saml, :with_email_id_format) }
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

    it 'returns saml attribute signed_response_message_requested if true' do
      expect(config_hash(saml_sp)).to include('signed_response_message_requested')
    end

    it 'returns saml attributes without signed_response_message_requested if false' do
      expect(config_hash(
        saml_without_requested_response,
      )).not_to include('signed_response_message_requested')
    end

    it 'returns saml attribute email_nameid_format_allowed if true' do
      expect(config_hash(
        saml_email_id_format,
      )).to include('email_nameid_format_allowed')
    end

    it 'truens saml attributes without email_nameid_format_allowed if false' do
      expect(config_hash(saml_sp)).not_to include('email_nameid_format_allowed')
    end

    it 'returns a properly formatted yaml blurb for OIDC pkce' do
      sp_config_oidc_attributes.push('pkce')
      sp_config_oidc_attributes.each do |attribute_name|
        expect(config_hash(oidc_pkce_sp)).to include(attribute_name)
      end
    end

    it 'returns a properly formatted yaml blurb for OIDC jwt' do
      sp_config_oidc_attributes.each do |attribute_name|
        expect(config_hash(oidc_jwt_sp)).to include(attribute_name)
      end
    end

    it 'returns a hash with IdV redirects if ial 2 - oidc' do
      sp_config_oidc_attributes.push('failure_to_proof_url')
      sp_config_oidc_attributes.each do |attribute_name|
        expect(config_hash(oidc_jwt_sp_2)).to include(attribute_name)
      end
    end

    it 'returns the ial config as an integer instead of a string' do
      expect(config_hash(saml_sp_ial_2)['ial']).to be_an(Integer)
    end

    it 'returns a hash with IdV redirects if ial 2 - saml' do
      sp_config_saml_attributes.push('failure_to_proof_url')
      sp_config_oidc_attributes.push('post_idv_follow_up_url')
      sp_config_saml_attributes.each do |attribute_name|
        expect(config_hash(saml_sp_ial_2)).to include(attribute_name)
      end
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

  describe '#sp_valid_logo_mime_types' do
    it 'equals the valid mime types' do
      expect(sp_valid_logo_mime_types).to eq(['image/png', 'image/svg+xml'])
    end
  end

  describe '#titleize' do
    describe 'when saml is passed in' do
      it 'returns SAML' do
        expect(titleize('saml')).to eq 'SAML'
      end
    end

    describe 'when open_id_connect_pkce is passed in' do
      it 'returns OpenID Connect PKCE' do
        expect(titleize('openid_connect_pkce')).to eq 'OpenID Connect PKCE'
      end
    end

    describe 'when open_id_connect_private_key_jwt is passed in' do
      it 'returns OpenID Connect Private Key JWT' do
        expect(titleize('openid_connect_private_key_jwt')).to eq 'OpenID Connect Private Key JWT'
      end
    end
  end

  describe '#sp_signed_response_message_requested_img_alt' do
    context 'sp_response_message_requested is true' do
      it 'returns a string saying signed response is requested' do
        expect(sp_signed_response_message_requested_img_alt(
          true,
        )).to eq 'Signed response message requested'
      end
    end

    context 'sp_response_message_requested is false' do
      it 'returns a string saying signed response is not requested' do
        expect(sp_signed_response_message_requested_img_alt(
          false,
        )).to eq 'Signed response message not requested'
      end
    end
  end

  describe '#readonly_help_text' do
    include Devise::Test::ControllerHelpers

    let(:user) { create(:user) }

    before do
      sign_in user
    end

    describe 'a non-admin user' do
      it 'returns true' do
        expect(helper.readonly_help_text?).to be true
      end
    end

    describe 'a login.gov admin user' do
      let(:user) { create(:logingov_admin) }

      it 'returns false' do
        expect(helper.readonly_help_text?).to be false
      end
    end
  end

  describe '#show_minimal_help_text_element' do
    include Devise::Test::ControllerHelpers
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    context 'when not a login.gov admin user' do
      describe 'when help text exists' do
        describe 'and is not blank' do
          let(:help_text) do
            {
              'sign_in' => { 'en' => '<b>Some sign-in help text</b>' },
              'sign_up' => { 'en' => '<b>Some sign-up help text</b>' },
              'forgot_password' => { 'en' => '<b>Some forgot password help text</b>' },
            }
          end

          it 'returns false' do
            service_provider = ServiceProvider.new(help_text:)
            expect(
              helper.show_minimal_help_text_element?(service_provider),
            ).to be false
          end
        end

        describe 'it is just empty strings' do
          let(:help_text) do
            {
              'sign_in' => { 'en' => '' },
              'sign_up' => { 'en' => '' },
              'forgot_password' => { 'en' => '' },
            }
          end

          it 'returns true' do
            service_provider = ServiceProvider.new(help_text:)
            expect(
              helper.show_minimal_help_text_element?(service_provider),
            ).to be true
          end
        end

        describe 'it is just empty strings with whitespace' do
          let(:help_text) do
            {
              'sign_in' => { 'en' => ' ' },
              'sign_up' => { 'en' => ' ' },
              'forgot_password' => { 'en' => '  ' },
            }
          end

          it 'returns true' do
            service_provider = ServiceProvider.new(help_text:)
            expect(
              helper.show_minimal_help_text_element?(service_provider),
            ).to be true
          end
        end

        describe 'it is just some empty hashes' do
          let(:help_text) do
            {
              'sign_in' => {},
              'sign_up' => {},
              'forgot_password' => {},
            }
          end

          it 'returns true' do
            service_provider = ServiceProvider.new(help_text:)
            expect(
              helper.show_minimal_help_text_element?(service_provider),
            ).to be true
          end
        end
      end
    end

    describe 'a login.gov admin' do
      let(:user) { create(:logingov_admin) }
      let(:help_text) { {} }

      it 'returns false' do
        service_provider = ServiceProvider.new(help_text:)
        expect(helper.show_minimal_help_text_element?(service_provider)).to be false
      end
    end
  end
end
