class ServiceProviderSerializer < ActiveModel::Serializer
  attributes(
    :acs_url,
    :active,
    :agency_id,
    :assertion_consumer_logout_service_url,
    :attribute_bundle,
    :block_encryption,
    :certs,
    :email_nameid_format_allowed,
    :friendly_name,
    :ial,
    :default_aal,
    :issuer,
    :logo,
    :remote_logo_key,
    :redirect_uris,
    :return_to_sp_url,
    :failure_to_proof_url,
    :push_notification_url,
    :signature,
    :sp_initiated_login_url,
    :updated_at,
    :help_text,
  )

  def agency
    object&.agency&.name
  end

  def agency_id
    object&.agency&.id
  end

  def certs
    object.certificates.map(&:to_pem)
  end

  def updated_at
    object.updated_at.iso8601
  end

  def signature
    Digest::SHA256.hexdigest unique_identifier
  end

  def remote_logo_key
    return unless object.logo_file.attached?
    object.logo_file.key
  end

  private

  def unique_identifier
    object.id.to_s + object.issuer + object.created_at.to_s + object.updated_at.to_s
  end
end
