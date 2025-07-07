require 'portal/constants'
require 'net/http'
require 'uri'

class ReportsController < AuthenticatedController
  include Portal::Constants
  include ActionController::Live

  def home
    # @teams = current_user.teams.includes(:users, :service_providers, :agency)
    # ...any other logic you need for show...

    default_start = Time.zone.today.beginning_of_week.to_s
    default_finish = Time.zone.today.end_of_week.to_s
    default_ial = 1
    default_env = 'local'
    default_funnel_mode = 'blanket'
    default_scale = 'count'
    default_by_agency = 'off'
    default_extra = false
    default_time_bucket = nil
    default_cumulative = true
    default_agency = nil
    default_issuer = nil

    start_param      = params[:start] || default_start
    finish_param     = params[:finish] || default_finish
    ial_param        = params[:ial] || default_ial
    agency_param     = params[:agency] || default_agency
    issuer_param     = params[:issuer] || default_issuer
    env_param        = default_env
    funnel_mode_param = %w[step
blanket].include?(params[:funnel_mode]) ? params[:funnel_mode] : default_funnel_mode
    scale_param = %w[count percent].include?(params[:scale]) ? params[:scale] : default_scale

    by_agency_param = params[:byAgency] || default_by_agency
    extra_param = if params[:extra].present? && params[:extra] != 'false' && params[:extra] != '0'
                    true
                  else
                    default_extra
                  end
    time_bucket_param = params[:time_bucket] || default_time_bucket
    cumulative_param = params[:cumulative].nil? ? default_cumulative : params[:cumulative]

    @start = start_param
    @finish = finish_param
    @ial = ial_param
    @agency = agency_param
    @issuer = issuer_param
    @env = env_param
    @funnel_mode = funnel_mode_param
    @scale = scale_param
    @by_agency = by_agency_param
    @extra = extra_param
    @time_bucket = time_bucket_param
    @cumulative = cumulative_param
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

  def stream_daily_auths_report
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
end


