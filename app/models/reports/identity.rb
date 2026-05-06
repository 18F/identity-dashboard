module Reports
  # A per-month IdV funnel report
  class Identity
    USAGE_KEYS = %w[
      count_newly_created_accounts
      count_existing_accounts
    ].freeze

    FRAUD_KEYS = %w[
      stayed_blocked
      inauthentic_doc
      facial_mismatch
      invalid_attributes_dl_dos
      ssn_dob_deceased
      fraud_alert
      address_other_not_found
      suspicious_phone
      lack_phone_ownership
      wrong_phone_type
      blocked_by_ipp_fraud
      pending_lg99_likely_fraud
    ].map { |key| "count_#{key}" }.freeze

    # Types of MFE used — `webauthn_platform` is face/touch and
    # `webauthn` is a security key that isn't face/touch
    MFA_KEYS = %w[
      totp_successful
      piv_cac_successful
      sms_successful
      voice_successful
      backup_code_successful
      personal_key_successful
      webauthn_platform_successful
      webauthn_successful
    ].map { |key| "count_#{key}" }.freeze

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
      @storage = AnalyticsReportStorage.new(issuer, chosen_date_as_string)
      @raw_data = @storage.fetch
    end

    def time_intervals
      1
    end

    def time_interval_size
      return 'month' if @storage.time_interval == 'monthly'
      return 'week' if @storage.time_interval == 'weekly'

      raise ArgumentError
    end

    def usage_data
      return unless usage_data_available?

      to_chartkick_with_i18n_labels(inner_data.keys.select { |key| USAGE_KEYS.include? key })
    end

    def fraud_data
      to_chartkick_with_i18n_labels(inner_data.keys.select { |key| FRAUD_KEYS.include? key })
    end

    def fraud_redress
      [['Pending Review', inner_data['count_pending_lg99_likely_fraud']],
       ['Adjudicated as Legitimate', inner_data['count_pass_via_lg99']]]
    end

    def mfa_data
      to_chartkick_with_i18n_labels(inner_data.keys.select { |key| MFA_KEYS.include? key })
    end

    def idv_data
      [['Newly Proofed', inner_data['count_newly_proofed_users']],
       ['Previously Verified', inner_data['count_preverified_users']]]
    end

    def data
      to_chartkick_with_i18n_labels(inner_data.keys)
    end

    def grand_total
      if usage_data_available?
        USAGE_KEYS.sum { |key| inner_data[key].to_i }
      else
        data_other.sum { |(_key, value)| value.to_i }
      end
    end

    def fraud_total
      inner_data.reduce(0) do |sum, (key, value)|
        next sum unless FRAUD_KEYS.include? key

        sum + value.to_i
      end
    end

    def provider_information
      return {} unless has_raw_data?

      @provider_information || @raw_data[0][0]['provider_information']
    end

    def report_information
      return {} unless has_raw_data?

      @report_information || @raw_data[0][0]['report_information']
    end

    private

    def usage_data_available?
      USAGE_KEYS.any? { |key| inner_data[key].present? }
    end

    def chosen_date_as_string
      chosen_date.beginning_of_month.strftime('%F %T')
    end

    def inner_data
      return {} unless has_raw_data?

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

    def has_raw_data?
      @raw_data.present? && @raw_data[0][0].any?
    end
  end
end
