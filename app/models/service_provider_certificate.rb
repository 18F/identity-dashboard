# A class to decorate a certificate, for easier warning and expiration
class ServiceProviderCertificate
  attr_reader :cert

  # @param [OpenSSL::X509::Certificate,String] cert
  def initialize(cert)
    Rails.logger.info(cert.class)
    @cert = cert
  end

  def method_missing(name, *args, &block)
    if cert.respond_to?(name)
      cert.send(name, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(name)
    cert.respond_to_missing?(name) || super
  end

  def expiration_time_to_colorized_s
    time_s = not_after.to_s
    if not_after < Time.zone.now
      time_s.colorize(color: :black, background: :red)
    elsif not_after < self.class.warning_period
      time_s.colorize(color: :black, background: :light_yellow)
    else
      time_s
    end
  end

  def self.warning_period
    (Figaro.env.certificate_expiration_warning_period || 60).to_i.days.from_now
  end

  def expiration_css_class
    if not_after < Time.zone.now
      'certificate-expired'
    elsif not_after < self.class.warning_period
      'certificate-warning'
    end
  end
end
