require 'portal/constants'
require 'net/http'
require 'uri'

class ReportsController < AuthenticatedController
  include Portal::Constants
  include ActionController::Live
  include ReportingParams


  def home
    # @teams = current_user.teams.includes(:users, :service_providers, :agency)
    # ...any other logic you need for show...

    rp = reporting_params(params)
    @start = rp[:start]
    @finish = rp[:finish]
    @ial = rp[:ial]
    @agency = rp[:agency]
    @issuer = rp[:issuer]
    @env = 'dev'
    @funnel_mode = rp[:funnel_mode]
    @scale = rp[:scale]
    @by_agency = rp[:by_agency]
    @extra = rp[:extra]
    @time_bucket = rp[:time_bucket]
    @cumulative = rp[:cumulative]
    @agency = 'Social Security Administration'

  end

  def download_daily_auths_report
    year = params[:year]
    date = params[:date]
    file_path = Rails.root.join('local', 'daily-auths-report', year,
"#{date}.daily-auths-report.json")

    if File.exist?(file_path)
      send_file file_path, type: 'application/json', disposition: 'inline'
    else
      render plain: 'Not found', status: :not_found
    end
  end

  def web_download_daily_auths_report
    year = params[:year]
    date = params[:date]
    remote_url = "https://public-reporting-data.prod.login.gov/prod/daily-auths-report/#{year}/#{date}.daily-auths-report.json"

    uri = URI.parse(remote_url)
    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      send_data response.body, type: 'application/json', disposition: 'inline'
    else
      render plain: 'Not found', status: :not_found
    end
  end

  def stream_daily_auths_report_old
    year = params[:year]
    date = params[:date]
    remote_url = "https://public-reporting-data.prod.login.gov/prod/daily-auths-report/#{year}/#{date}.daily-auths-report.json"

    uri = URI.parse(remote_url)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new(uri)
      http.request(request) do |res|
        if res.is_a?(Net::HTTPSuccess)
          response.headers['Content-Type'] = 'application/json'
          response.headers['Content-Disposition'] = 'inline'
          res.read_body do |chunk|
            response.stream.write chunk
          end
        else
          render plain: 'Not found', status: :not_found
        end
      end
    end
  ensure
    response.stream.close
  end

  def stream_daily_auths_report
    year = params[:year]
    date = params[:date]
    remote_url = "https://public-reporting-data.prod.login.gov/prod/daily-auths-report/#{year}/#{date}.daily-auths-report.json"

    uri = URI.parse(remote_url)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new(uri)
      http.request(request) do |res|
        if res.is_a?(Net::HTTPSuccess)
          json = JSON.parse(res.body)

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

end

