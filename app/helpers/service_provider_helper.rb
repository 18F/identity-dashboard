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

  private

  def config_hash(service_provider)
    clean_sp_json = service_provider.to_json(except: SP_PROTECTED_ATTRIBUTES)
    hash_from_clean_json = JSON.parse(clean_sp_json)
    config_hash = formatted_config_hash(hash_from_clean_json)
    config_hash['agency'] = "'#{service_provider.agency.name}'" if service_provider.agency
    config_hash
  end

  # rubocop:disable Metrics/LineLength
  def formatted_config_hash(sp_json)
    sp_json.map do |config_key, value|
      if %w[agency_id default_help_text help_text attribute_bundle redirect_uris].include?(config_key)
        [config_key, value]
      elsif config_key == 'saml_client_cert'
        ['cert', value]
      else
        [config_key, "'#{value}'"]
      end
    end.to_h
  end
  # rubocop:enable Metrics/LineLength
end
