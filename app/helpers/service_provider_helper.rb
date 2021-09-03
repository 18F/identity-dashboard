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
    production_issuer
  ].freeze

  PNG_MIME_TYPE = 'image/png'.freeze
  SVG_MIME_TYPE = 'image/svg+xml'.freeze
  SP_VALID_LOGO_MIME_TYPES = [
    PNG_MIME_TYPE,
    SVG_MIME_TYPE,
  ].freeze

  PNG_EXT = '.png'.freeze
  SVG_EXT = '.svg'.freeze
  SP_VALID_LOGO_EXTENSIONS = [
    PNG_EXT,
    SVG_EXT,
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
    SP_VALID_LOGO_MIME_TYPES
  end

  def valid_image_type?(filename)
    SP_VALID_LOGO_EXTENSIONS.each do |ext|
      return true if filename.downcase.end_with? ext
    end
  end

  def mime_type(filename)
    name = filename.downcase
    return PNG_MIME_TYPE if name.end_with? PNG_EXT
    return SVG_MIME_TYPE if name.end_with? SVG_EXT
    nil
  end

  # Generate the list for the SP edit form, including a nil entry
  def redirect_uri_list(service_provider = @service_provider)
    values = service_provider.redirect_uris || []
    values << nil
  end

  def yamlized_sp(service_provider)
    key_from_issuer = JSON.parse(service_provider.to_json).dig('production_issuer').presence ||
                      service_provider.issuer
    yamlable_json = { "'#{key_from_issuer}'" => config_hash(service_provider) }
    yamlable_json.to_yaml.delete('\"')
  end

  def sp_active_img_alt(service_provider_is_active)
    return 'Active service provider' if service_provider_is_active
    'Inactive service provider'
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

  private

  def config_hash(service_provider)
    clean_sp_json = service_provider.to_json(except: SP_PROTECTED_ATTRIBUTES)
    hash_from_clean_json = JSON.parse(clean_sp_json)
    config_hash = formatted_config_hash(hash_from_clean_json)
    config_hash['protocol'] = service_provider.identity_protocol
    map_config_attributes(config_hash, service_provider.id, service_provider.agency)
  end

  # rubocop:disable Layout/LineLength
  def formatted_config_hash(sp_json)
    sp_json.map do |config_key, value|
      if %w[agency_id default_help_text help_text attribute_bundle redirect_uris].include?(config_key)
        [config_key, value]
      else
        [config_key, "'#{value}'"]
      end
    end.to_h
  end
  # rubocop:enable Layout/LineLength

  def map_config_attributes(sp_hash, sp_id, agency = {name => '', id => nil})
    base_hash = {
      'agency_id' => agency['id'],
      'friendly_name' => sp_hash['friendly_name'],
      'agency' => agency['name'],
      'logo' => '<REPLACE_ME.png>',
      'certs' => '<REPLACE_ME>',
      'return_to_sp_url' => sp_hash['return_to_sp_url'],
      'redirect_uris' => sp_hash['redirect_uris'],
      'ial' => sp_hash['ial'],
      'attribute_bundle' => sp_hash['attribute_bundle'],
      'restrict_to_deploy_env' => 'prod',
      'protocol' => sp_hash['protocol'],
      'help_text' => sp_hash['help_text'],
      'app_id' => sp_id,
      'launch_date' => '<REPLACE_ME>',
      'iaa' => '<REPLACE_ME>',
      'iaa_start_date' => '<REPLACE_ME>',
      'iaa_end_date' => '<REPLACE_ME>',
    }
    hash_with_ial_attr = add_IAL_attribute(base_hash, sp_hash['failure_to_proof_url'])
    if hash_with_ial_attr['protocol'] == 'saml'
      add_saml_attributes(hash_with_ial_attr)
    else
      add_pkce_atttribute(hash_with_ial_attr)
    end
  end

  # rubocop:disable Layout/LineLength
  def add_saml_attributes(configs_hash)
    saml_attrs = {
      'acs_url' => configs_hash['acs_url'],
      'assertion_consumer_logout_service_url' => configs_hash['assertion_consumer_logout_service_url'],
      'block_encryption' => configs_hash['block_encryption'],
      'sp_initiated_login_url' => configs_hash['sp_initiated_login_url'],
    }
    configs_hash.merge!(saml_attrs)
  end
  # rubocop:enable Layout/LineLength

  def add_IAL_attribute(config_hash, failure_to_proof_url)
    return config_hash if config_hash['ial'] != "'2'"
    config_hash.merge({'failure_to_proof_url' => failure_to_proof_url})
  end

  def add_pkce_atttribute(config_hash)
    return config_hash if config_hash['protocol'] != 'openid_connect_pkce'
    config_hash.merge({'pkce' => true })
  end
end
