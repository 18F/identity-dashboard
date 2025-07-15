class Analytics::ServiceProvidersController < ApplicationController # :nodoc:
  before_action -> { authorize User, policy_class: AnalyticsPolicy }
  before_action :check_feature_flag

  # analytics/service/providers/{id}
  def show
    @issuer = service_provider.issuer
    @friendly_name = service_provider.friendly_name.capitalize
  end

  def stream_daily_auths_report
    year = params[:year]
    date = params[:date]
    issuer = session[:issuer]

    if issuer.blank?
      render plain: 'No issuer in session', status: :bad_request
      return
    end

    # Validate date format (ISO 8601: YYYY-MM-DD)
    unless is_valid_date?(date)
      render plain: 'Invalid date format. Expected ISO format (YYYY-MM-DD)', status: :bad_request
      return
    end

    unless is_valid_year?(date)
      render plain: 'Invalid year format. Expected (YYYY)', status: :bad_request
      return
    end

    remote_url = "#{IdentityConfig.store.reporting_baseurl}/#{IdentityConfig.store.reporting_daily_auths_dir}/#{year}/#{date}.#{IdentityConfig.store.reporting_daily_auths_file}"

    uri = URI.parse(remote_url)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new(uri)
      http.request(request) do |res|
        if res.is_a?(Net::HTTPSuccess)
          json = JSON.parse(res.body)
          json['results'] = json['results'].select { |entry| entry['issuer'] == issuer }
          response.headers['Content-Type'] = 'application/json'
          response.headers['Content-Disposition'] = 'inline'
          response.stream.write JSON.generate(json)
        else
          render plain: 'Remote server error', status: :not_found
        end
      end
    end
  ensure
    response.stream.close
  end

  private

  def check_feature_flag
    return if IdentityConfig.store.analytics_dashboard_enabled

    render plain: 'Disabled', status: :not_found

  end

  def service_provider
    @service_provider ||= ServiceProvider.includes(
      :agency,
      logo_file_attachment: :blob,
    ).find(id)
  end

  def id
    @id ||= params[:id]
  end

  def is_valid_date?(date_string)
    return false if date_string.blank?

    # Check if it matches ISO date format (YYYY-MM-DD)
    return false unless date_string.match?(/^\d{4}-\d{2}-\d{2}$/)

    # Validate it's a real date
    Date.parse(date_string)
    true
  rescue Date::Error
    false
  end

  def is_valid_year?(year_string)
    return false if year_string.blank?

    # Check if it matches year format (YYYY)
    return false unless year_string.match?(/^\d{4}$/)

    year = year_string.to_i
    current_year = Date.current.year

    # Validate it's a valid year within acceptable range
    earliest_year = IdentityConfig.store.analytics_earliest_year

    return if year >= earliest_year && year <= current_year

      false

  end
end
