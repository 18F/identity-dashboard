module Reports
  # A per-month IdV funnel report
  class Identity
    FRICTION_KEYS = %w[
      doc_auth_ux
      doc_auth_technical_issue
      doc_auth_processing_issue
      selfie_ux
      false_rejection_inauthentic_doc
      dob_incorrect
      ssn_incorrect
      identity_not_found
      friction_during_otp
    ].map { |key| "count_#{key}" }.freeze

    FRAUD_KEYS = %w[
      inauthentic_doc
      facial_mismatch
      invalid_attributes_dl_dos
      ssn_dob_deceased
      fraud_alert
      address_other_not_found
      suspicious_phone
      lack_phone_ownership
      wrong_phone_type
      stayed_blocked
      blocked_by_ipp_fraud
      pending_lg99_likely_fraud
    ].map { |key| "count_#{key}" }.freeze

    attr_reader :issuer, :chosen_date

    def self.available_dates(configs)
      reports = configs.flat_map do |config|
        AnalyticsReportStorage.list(config.issuer)
      end

      reports.map do |report|
        File.basename(report.key, File.extname(report.key))
      end
    end

    def initialize(analytic)
      @issuer = analytic.config&.issuer
      @chosen_date = DateTime.parse(analytic.date) if analytic.date.present?
      @chosen_date ||= DateTime.now
      @raw_data = AnalyticsReportStorage.fetch(issuer, chosen_date_as_string)
    end

    def data
      to_chartkick_with_i18n_labels(inner_data.keys)
    end

    def data_other
      data - fraud_data
    end

    def fraud_data
      to_chartkick_with_i18n_labels(inner_data.keys.select { |key| FRAUD_KEYS.include? key })
    end

    private

    def chosen_date_as_string
      chosen_date.beginning_of_month.strftime('%F %T')
    end

    def inner_data
      return {} unless @raw_data.present? && @raw_data[0][0].any?

      @inner_data ||= @raw_data[0][0]['data']
    end

    def to_chartkick_with_i18n_labels(keys)
      keys.each_with_object([]) do |key, results|
        begin
          label = I18n.t("reports.#{key}")
        rescue I18n::MissingTranslationData
          next
        end

        results.push([label, inner_data[key]])
      end
    end
  end
end
