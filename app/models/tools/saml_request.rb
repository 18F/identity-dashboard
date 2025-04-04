module Tools
  class SamlRequest
    attr_reader :auth_url, :cert_body
    attr_accessor :errors

    def initialize(params)
      @auth_url = params['auth_url']
      @cert_body = params['cert']
      @errors = []
    end

    def run_validations
      valid_signature if valid
    end

    def matching_cert_sn
      auth_request.matching_cert.serial
    end

    def logout_request?
      auth_request.logout_request?
    end

    def cert_errors
      auth_request.cert_errors
    end

    def xml
      document.to_xml
    end

    def xml_valid?
      document.errors.empty?
    end

    def valid
      return @valid if defined? @valid

      @valid = auth_request.valid?
    end

    def valid_signature
      return @valid_signature if defined? @valid_signature

      @valid_signature = check_signature_validity
    end

    def signed?
      auth_request.signed?
    end

    def sp
      @sp ||= ServiceProvider.find_by(issuer: auth_request&.issuer)
    end

    private

    def certs
      cert_body.blank? ? sp&.certs : [cert_body]
    end

    def check_signature_validity
      if auth_request.issuer.nil?
        @errors.push(<<~EOS.squish)
          No Issuer value found in request.
          Please check Issuer attribute.
        EOS

        return false
      end

      if sp.nil?
        @errors.push(<<~EOS.squish)
          No registered Service Provider matched the Issuer in this request.
          Please check Issuer attribute.
        EOS

        return false
      end

      if certs.nil?
        @errors.push(<<~EOS.squish)
          Could not find any certificates to use. Please add a
          certificate to your application configuration or paste one below.
        EOS

        return false
      end

      begin
        auth_service_provider.certs = valid_certs
      rescue OpenSSL::X509::CertificateError
        @errors.push('Something is wrong with the certificate you submitted.')
        return false
      end

      auth_service_provider.valid_signature?(
        auth_request.matching_cert,
        true,
      )
    end

    def document
      Nokogiri.XML(auth_request.raw_xml)
    end

    def valid_certs
      certs.map { |cert| OpenSSL::X509::Certificate.new(cert) }
    end

    def auth_request
      @auth_request ||= SamlIdp::Request.
        from_deflated_request(
          saml_params[:SAMLRequest],
          get_params: saml_params,
        )
    end

    def auth_service_provider
      @auth_service_provider ||= auth_request.service_provider
    end

    def saml_params
      @saml_params ||= begin
        s_params = url_params(auth_url)
        s_params.present? ? s_params : { SAMLRequest: auth_url }
      end
    end

    def url_params(url)
      CGI.parse(url.split('?')[1..].join('?')).to_h { |k, v| [ k.to_sym, v[0] ] }
    end
  end
end
