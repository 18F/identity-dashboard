# A class to decorate a certificate, for easier warning and expiration
class ServiceProviderCertificate
  attr_reader :cert

  # @param [OpenSSL::X509::Certificate,String] cert
  def initialize(cert)
    @cert = cert
  end

  def method_missing(name, *, &)
    if cert.respond_to?(name)
      cert.send(name, *, &)
    else
      super
    end
  end

  def respond_to_missing?(name, include_private = false)
    cert.respond_to?(name) || super
  end

  # Simplistic check that makes array comparisons work more easily in specs
  def ==(other)
    subject == other.subject &&
      serial == other.serial
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
    IdentityConfig.store.certificate_expiration_warning_period.days.from_now
  end

  def expiration_css_class
    if not_after < Time.zone.now
      'certificate-expired'
    elsif not_after < self.class.warning_period
      'certificate-warning'
    end
  end
end
