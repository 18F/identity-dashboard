#:reek:UtilityFunction
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

  def sp_logo(file_name)
    file = file_name || 'generic.svg'
    if file.end_with?('.svg')
      link_to(file, sp_logo_preview_path(file))
    else
      image_tag(sp_logo_path(file))
    end
  end

  def sp_logo_path(file_name)
    file = file_name || 'generic.svg'
    'https://raw.githubusercontent.com/18F/identity-idp/master/app/assets/images/sp-logos/' +
      file
  end

  def sp_logo_preview_path(file_name)
    file = file_name || 'generic.svg'
    'https://github.com/18F/identity-idp/blob/master/app/assets/images/sp-logos/' +
      file
  end

  #:reek:FeatureEnvy
  def yamlized_sp(service_provider)
    key_from_issuer = JSON.parse(service_provider.to_json).dig('production_issuer').presence ||
                      service_provider.issuer
    yamlable_json = { "'#{key_from_issuer}'" => config_hash(service_provider) }
    yamlable_json.to_yaml.delete('\"')
  end

  private

  #:reek:FeatureEnvy, :reek:DuplicateMethodCall
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
      else
        [config_key, "'#{value}'"]
      end
    end.to_h
  end
  # rubocop:enable Metrics/LineLength
end
