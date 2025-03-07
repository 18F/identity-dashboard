module ServiceProviderHelper
  SP_PROTECTED_ATTRIBUTES = %w[
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
  ].freeze

  def sp_logo(file_name)
    file = file_name || 'generic.svg'
    if file.downcase.end_with?('.svg')
      link_to(file, sp_logo_preview_path(file))
    else
      image_tag(sp_logo_path(file))
    end
  end

  def sp_logo_path(file_name)
    file = file_name || 'generic.svg'
    'https://raw.githubusercontent.com/18F/identity-idp/main/app/assets/images/sp-logos/' +
      file
  end

  def sp_logo_preview_path(file_name)
    file = file_name || 'generic.svg'
    'https://github.com/18F/identity-idp/blob/main/app/assets/images/sp-logos/' +
      file
  end

  def sp_valid_logo_mime_types
    LogoValidator::SP_VALID_LOGO_MIME_TYPES
  end

  def titleize(protocol)
    case protocol
    when 'saml'
      'SAML'
    when 'openid_connect_pkce'
      'OpenID Connect PKCE'
    when 'openid_connect_private_key_jwt'
      'OpenID Connect Private Key JWT'
    end
  end

  # Generate the list for the SP edit form, including a nil entry
  def redirect_uri_list(service_provider = @service_provider)
    values = service_provider.redirect_uris || []
    values << nil
  end

  def yamlized_sp(service_provider)
    key_from_issuer = service_provider.issuer
    yamlable_json = { "#{key_from_issuer}" => config_hash(service_provider) }
    yamlable_json.to_yaml.delete('\"')
  end

  def sp_allow_prompt_login_img_alt(sp_allows_prompt_login)
    return 'prompt=login enabled' if sp_allows_prompt_login

    'prompt=login disabled'
  end

  def sp_email_nameid_format_allowed_img_alt(sp_email_nameid_format_allowed)
    return 'Email NameID format allowed' if sp_email_nameid_format_allowed

    'Email NameID format prohibited'
  end

  def sp_signed_response_message_requested_img_alt(sp_response_message_requested)
    return 'Signed response message requested' if sp_response_message_requested

    'Signed response message not requested'
  end

  def sp_attribute_bundle(service_provider)
    return '' unless service_provider.attribute_bundle.present?

    service_provider.attribute_bundle.select do |attribute|
      ServiceProvider.possible_attributes.include? attribute
    end.sort.join(', ')
  end

  def help_text_options_enabled?
    IdentityConfig.store.help_text_options_feature_enabled
  end

  def show_analytics_column?
    current_user.logingov_admin?
  end

  def service_provider_policy
    Pundit.policy(current_user, @service_provider || ServiceProvider)
  end

  def readonly_help_text?
    !service_provider_policy.edit_custom_help_text?
  end

  def show_minimal_help_text_element?(service_provider)
    return false if service_provider_policy.edit_custom_help_text?

    text_info = HelpText.lookup(service_provider:)
    text_info.blank? || text_info.presets_only?
  end

  private

  def config_hash(service_provider)
    clean_sp_json = service_provider.to_json(except: SP_PROTECTED_ATTRIBUTES)
    hash_from_clean_json = JSON.parse(clean_sp_json)
    config_hash = formatted_config_hash(hash_from_clean_json)
    config_hash['protocol'] = service_provider.identity_protocol
    config_hash['ial'] = service_provider.ial.to_i
    map_config_attributes(config_hash, service_provider)
  end

  # rubocop:disable Layout/LineLength
  def formatted_config_hash(sp_json)
    sp_json.map do |config_key, value|
      if %w[agency_id default_help_text help_text attribute_bundle redirect_uris].include?(config_key)
        [config_key, value]
      else
        [config_key, value]
      end
    end.to_h
  end
  # rubocop:enable Layout/LineLength

  def map_config_attributes(sp_hash, sp)
    agency = sp.agency || {}
    base_hash = {
      'agency_id' => agency['id'],
      'friendly_name' => sp_hash['friendly_name'],
      'agency' => agency['name'],
      'logo' => '<REPLACE_ME.png>',
      'certs' => '<REPLACE_ME>',
      'ial' => sp_hash['ial'],
      'default_aal' => sp_hash['default_aal'],
      'attribute_bundle' => sp_hash['attribute_bundle'],
      'protocol' => sp_hash['protocol'],
      'restrict_to_deploy_env' => 'prod',
      'help_text' => sp_hash['help_text'],
      'app_id' => '<REPLACE_WITH_COMMS>',
      'launch_date' => '<REPLACE_ME>',
      'iaa' => '<REPLACE_ME>',
      'iaa_start_date' => '<REPLACE_ME>',
      'iaa_end_date' => '<REPLACE_ME>',
      'return_to_sp_url' => sp_hash['return_to_sp_url'],
      'push_notification_url' => sp_hash['push_notification_url'],
      'redirect_uris' => sp_hash['redirect_uris'],
    }
    hash_with_ial_attr = add_IAL_attribute(
      base_hash, sp_hash['failure_to_proof_url']
    )

    if base_hash['protocol'] == 'saml'
      add_saml_attributes(hash_with_ial_attr, sp_hash)
    else
      add_oidc_attributes(hash_with_ial_attr)
    end
  end

  def add_saml_attributes(configs_hash, sp_hash)
    saml_attrs = {
      'acs_url' => sp_hash['acs_url'],
      'assertion_consumer_logout_service_url' => sp_hash['assertion_consumer_logout_service_url'],
      'sp_initiated_login_url' => sp_hash['sp_initiated_login_url'],
      'block_encryption' => sp_hash['block_encryption'],
      'protocol' => 'saml',
    }
    if sp_hash['signed_response_message_requested'] == true
      saml_attrs['signed_response_message_requested'] = true
    end
    if sp_hash['email_nameid_format_allowed'] == true
      saml_attrs['email_nameid_format_allowed'] = true
    end
    configs_hash.merge!(saml_attrs)
  end

  def add_IAL_attribute(config_hash, failure_to_proof_url)
    return config_hash if config_hash['ial'] != 2

    config_hash.merge(
      'failure_to_proof_url' => failure_to_proof_url,
    )
  end

  def add_oidc_attributes(config_hash)
    if config_hash['protocol'] == 'openid_connect_pkce'
      config_hash.merge({ 'pkce' => true, 'protocol' => 'oidc' })
    else
      config_hash.merge({ 'pkce' => false, 'protocol' => 'oidc' })
    end
  end

  def edit_button_goes_to_wizard?
    IdentityConfig.store.service_config_wizard_enabled &&
      IdentityConfig.store.edit_button_uses_service_config_wizard
  end
end
