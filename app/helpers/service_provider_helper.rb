#:reek:UtilityFunction
module ServiceProviderHelper
  SP_PROTECTED_ATTRIBUTES = %w[
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

  #:reek:DuplicateMethodCall
  def yamlized_sp(service_provider)
    key_from_issuer = JSON.parse(service_provider.to_json).dig('production_issuer').presence ||
                      clean_sp_hash(service_provider).dig('issuer')
    yamlable_json = { key_from_issuer => clean_sp_hash(service_provider).except('issuer') }
    yamlable_json.to_yaml
  end

  private

  #:reek:DuplicateMethodCall
  def clean_sp_hash(service_provider)
    clean_sp_json = service_provider.to_json(except: SP_PROTECTED_ATTRIBUTES)
    hash_from_clean_json = JSON.parse(clean_sp_json)
    hash_from_clean_json['agency'] = service_provider.agency.name if service_provider.agency
    hash_from_clean_json
  end
end
