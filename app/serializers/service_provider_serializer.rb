class ServiceProviderSerializer < ActiveModel::Serializer
  attributes(
    :acs_url,
    :active,
    :agency_id,
    :assertion_consumer_logout_service_url,
    :attribute_bundle,
    :block_encryption,
    :cert,
    :friendly_name,
    :ial,
    :issuer,
    :logo,
    :logo_file_blob_key,
    :logo_file_blob_content_type,
    :redirect_uris,
    :return_to_sp_url,
    :failure_to_proof_url,
    :push_notification_url,
    :signature,
    :sp_initiated_login_url,
    :updated_at,
    :help_text
  )

  def agency
    object&.agency&.name
  end

  def cert
    object.saml_client_cert
  end

  def logo_file_blob_key
    object.logo_file&.attachment&.blob&.key
  end

  def logo_file_blob_content_type
    object.logo_file&.attachment&.blob&.content_type
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
