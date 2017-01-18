class ServiceProviderSerializer < ActiveModel::Serializer
  attributes(
    :friendly_name,
    :issuer,
    :agency,
    :acs_url,
    :assertion_consumer_logout_service_url,
    :sp_initiated_login_url,
    :block_encryption,
    :cert,
    :return_to_sp_url,
    #:logo,
    :attribute_bundle,
    :updated_at,
    :signature
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
