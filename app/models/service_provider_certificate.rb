# A class to provide colorized expiration text
class ServiceProviderCertificate < OpenSSL::X509::Certificate
  def expiration_time_to_colorized_s
    self.class.expiration_time_to_colorized_s(not_after)
  end

  def self.expiration_time_to_colorized_s(time)
    time_s = time.to_s
    if time < Time.zone.now
      time_s.colorize(color: :black, background: :red)
    elsif time < warning_period
      time_s.colorize(color: :black, background: :light_yellow)
    else
      time_s
    end
  end

  def self.warning_period
    (Figaro.env.certificate_expiration_warning_period || 60).to_i.days.from_now
  end
end
