class ServiceProviderSerializer < ActiveModel::Serializer
  attributes(
    :acs_url,
    :active,
    :assertion_consumer_logout_service_url,
    :attribute_bundle,
    :block_encryption,
    :cert,
    :friendly_name,
    :issuer,
    :logo,
    :redirect_uris,
    :return_to_sp_url,
    :signature,
    :sp_initiated_login_url,
    :updated_at,
  )

  def agency
    object.agency.name
  end

  def cert
    object.saml_client_cert
  end

  def updated_at
    object.updated_at.iso8601
  end

  def signature
    Digest::SHA256.hexdigest unique_identifier
  end

  private

  def unique_identifier
    object.id.to_s + object.issuer + object.created_at.to_s + object.updated_at.to_s
  end
end
