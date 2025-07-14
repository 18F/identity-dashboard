class Analytics::ServiceProvidersController < ApplicationController # :nodoc:
  before_action -> { authorize User, policy_class: AnalyticsPolicy }
  # analytics/service/providers/{id}
  def show
    @issuer = service_provider.issuer
    @friendly_name = service_provider.friendly_name.capitalize
  end

  def stream_daily_auths_report
    year = params[:year]
    date = params[:date]
    issuer = session[:issuer]
    remote_url = "https://public-reporting-data.prod.login.gov/prod/daily-auths-report/#{year}/#{date}.daily-auths-report.json"

    uri = URI.parse(remote_url)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new(uri)
      http.request(request) do |res|
        if res.is_a?(Net::HTTPSuccess)
          json = JSON.parse(res.body)
          if issuer.present?
            json['results'] = json['results'].select { |entry| entry['issuer'] == issuer }
          end
          response.headers['Content-Type'] = 'application/json'
          response.headers['Content-Disposition'] = 'inline'
          response.stream.write JSON.generate(json)
        else
          render plain: 'Not found', status: :not_found
        end
      end
    end
  ensure
    response.stream.close
  end

  private

  def service_provider
    @service_provider ||= ServiceProvider.includes(:agency,
logo_file_attachment: :blob).find(id)
  end

  def id
    @id ||= params[:id]
  end
end
