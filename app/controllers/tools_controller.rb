class ToolsController < ApplicationController
  require 'saml_idp'

  def index
    flash[:error] = nil

    if !auth_params
      flash[:error] = 'Please submit an auth URL or SAMLRequest to be validated.'
      return
    end

    sp = ServiceProvider.find_by(issuer: auth_request.issuer) unless cert_param

    begin
      certs = (cert_param || sp.certs).map { |cert| OpenSSL::X509::Certificate.new(cert) }
    rescue OpenSSL::X509::CertificateError
      flash[:error] = 'Something is wrong with the certificate you submitted.'
    rescue NoMethodError
      flash[:error] = 'Could not find any certificates to use. Please add a certificate to your application configuration or paste one below.'
    end

    auth_service_provider&.certs = certs
    @valid_request = valid_request

    @valid_signature = valid_signature
    @matching_cert_sn = matching_cert_sn

    if auth_request
      xml = REXML::Document.new(auth_request.raw_xml)
      xml.write(@xml = '', 2)
    end

  end

  def valid_request
    auth_request&.valid?
  end

  def valid_signature
    auth_service_provider&.valid_signature?(Saml::XML::Document.parse(auth_request&.raw_xml), true, auth_request&.options)
  end

  private

  def matching_cert_sn
    auth_service_provider&.matching_cert&.serial
  end

  def auth_request
    @auth_request ||= SamlIdp::Request.from_deflated_request(auth_url, get_params:auth_params)
  end

  def auth_service_provider
    @auth_service_provider ||= auth_request&.service_provider
  end

  def cert_param
    [params['cert']] if params['cert'].present?
  end

  def auth_params
    @auth_params ||= auth_request_params
  end

  def auth_request_params
    return nil if auth_url.empty?
    return {SAMLRequest: auth_url} if !saml_request_params.present?
    saml_request_params
  end

  def auth_url
    @auth_url ||= params['auth_url']
  end

  def saml_request_params
    url_params(auth_url)
  end

  def url_params(url)
    CGI.parse(url.split('?')[1..].join('?')).to_h { |k, v| [ k.to_sym, v[0] ] }
  end
end
