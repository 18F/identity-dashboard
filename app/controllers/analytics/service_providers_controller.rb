class Analytics::ServiceProvidersController < ServiceProvidersController # :nodoc:
  skip_before_action :log_change
  before_action -> { authorize User, policy_class: AnalyticsPolicy }
  before_action -> {
    authorize service_provider, policy_class: AnalyticsPolicy
  }, only: %i[show stream_daily_auths_report]
  before_action :check_feature_flag

  # analytics/service/providers/{id}
  def show
    @issuer = service_provider.issuer
    @friendly_name = service_provider.friendly_name.capitalize
    @id = params[:id]
  end

  def stream_daily_auths_report
    year = params[:year]
    date = params[:date]
    issuer = service_provider.issuer

    unless is_valid_issuer?(issuer)
      render plain: 'Invalid issuer', status: :not_found
      return
    end

    unless is_valid_date?(date)
      render plain: 'Invalid date format. Expected ISO format (YYYY-MM-DD)', status: :bad_request
      return
    end

    unless is_valid_year?(year)
      render plain: 'Invalid year format. Expected (YYYY)', status: :bad_request
      return
    end

    base_url = IdentityConfig.store.analytics_baseurl
    directory = IdentityConfig.store.analytics_daily_auths_dir
    file_name = IdentityConfig.store.analytics_daily_auths_file

    remote_url = "#{base_url}/#{directory}/#{year}/#{date}.#{file_name}"

    uri = URI.parse(remote_url)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new(uri)
      http.request(request) do |res|
        if has_valid_json?(res)
          filtered_json = process_and_filter_json(res.body, issuer)
          response.headers['Content-Type'] = 'application/json'
          response.headers['Content-Disposition'] = 'inline'
          response.stream.write JSON.generate(filtered_json)
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

  def has_valid_json?(http_response)
    false unless http_response.is_a?(Net::HTTPSuccess) && http_response.present?
    begin
      json = JSON.parse(http_response.body)
      json.key?('results')
    rescue JSON::ParserError
      false
    end
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

    return false unless year_string.match?(/^\d{4}$/)

    # Validate it's a valid year within acceptable range
    year = year_string.to_i

    current_year = Date.current.year
    minimum_year = IdentityConfig.store.analytics_minimum_year

    year >= minimum_year && year <= current_year
  end

  # Probably unnecessary need to check SP model and see if issuer is a required entry
  def is_valid_issuer?(issuer)
    return false if issuer.blank?

    ServiceProvider.exists?(issuer:)
  end

  def process_and_filter_json(json_body, issuer)
    json = JSON.parse(json_body)
    json['results'] = json['results'].select { |entry| entry['issuer'] == issuer }
    json
  end
end
