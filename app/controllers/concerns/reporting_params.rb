module ReportingParams
  extend ActiveSupport::Concern

  def reporting_params(params)
    # Data lags one day behind
    default_start = Time.zone.yesterday.beginning_of_week.to_s
    default_finish = Time.zone.yesterday.end_of_week.to_s
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

    {
      start: params[:start] || default_start,
      finish: params[:finish] || default_finish,
      env: default_env,

      ial: params[:ial] || default_ial,
      agency: params[:agency] || default_agency,
      issuer: params[:issuer] || default_issuer,

      by_agency: params[:byAgency] || default_by_agency,
      time_bucket: params[:time_bucket] || default_time_bucket,

      # these params need type safety checks
      funnel_mode: %w[step
blanket].include?(params[:funnel_mode]) ? params[:funnel_mode] : default_funnel_mode,
      scale: %w[count percent].include?(params[:scale]) ? params[:scale] : default_scale,

      extra: (params[:extra].present? && params[:extra] != 'false' && params[:extra] != '0') ? true : default_extra,


      cumulative: params[:cumulative].nil? ? default_cumulative : params[:cumulative],
    }
  end
end