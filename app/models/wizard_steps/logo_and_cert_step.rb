module WizardSteps
  # Public certificates and the partner logo for the service provider.
  class LogoAndCertStep
    include ActiveModel::Validations
    def self.fields
      {
        certs: [],
        logo_name: '',
        remote_logo_key: '',
      }
    end

    def self.step_name
      'logo_and_cert'
    end

    validates_with CertsArePemsValidator, on: 'logo_and_cert'
    validates_with SamlCertsPresentValidator, on: 'logo_and_cert'
    validates_with LogoValidator, on: 'logo_and_cert'

    # @param wizard_step [WizardStep] the record this step reads and writes through
    def initialize(wizard_step)
      @wizard_step = wizard_step
    end

    # @return [Array<ServiceProviderCertificate>]
    # @raise [NameError] if this step doesn't have certs
    def certificates
      @certificates ||= Array(certs).map do |cert|
        ServiceProviderCertificate.new(OpenSSL::X509::Certificate.new(cert))
      rescue OpenSSL::X509::CertificateError
        null_certificate
      end
    end

    def remove_certificate(serial)
      certs.delete_if do |cert|
        OpenSSL::X509::Certificate.new(cert).serial.to_s == serial.to_s
      rescue OpenSSL::X509::CertificateError
        nil
      end

      # clear memoization for #certificates
      @certificates = nil

      serial
    end

    def attach_logo(logo_data)
      @wizard_step.logo_file = logo_data
      @wizard_step.wizard_form_data = wizard_form_data.merge({
        logo_name: logo_file.filename.to_s,
        remote_logo_key: logo_file.key,
      })
    end

    def pending_or_current_logo_data
      return attachment_changes_string_buffer if attachment_changes['logo_file'].present?

      logo_file&.blob&.download
    end
  end
end
