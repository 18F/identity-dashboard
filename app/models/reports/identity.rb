module Reports
  # A per-month IdV funnel report
  class Identity # rubocop:disable Metrics/ClassLength -- TODO: I plan to fix this in a fast-follow MR
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

    # @param configs [Array] of ServiceProvider records
    # @param user [User] usually the `current_user`
    def self.available_dates(configs, user)
      issuers = configs.map(&:issuer)
      reports = list_all_reports(user).filter { |key| issuers.include?(key) }

      reports.transform_values do |values|
        values.map do |report|
          File.basename(report.key, File.extname(report.key))
        end
      end.to_h
    end

    def self.list_all_reports(user)
      issuers = user.scoped_service_providers.map(&:issuer)
      AnalyticsReportStorage.list_by_issuer(issuers)
    end

    private_class_method :list_all_reports

    def initialize(analytic)
      @issuer = analytic.config&.issuer
      @chosen_date = DateTime.parse(analytic.date) if analytic.date_valid?
      @chosen_date ||= DateTime.now
      @storage = AnalyticsReportStorage.new(issuer, chosen_date_as_string)
      @raw_data = unwrap(@storage.fetch)
    end

    def time_interval_size
      return 'month' if @storage.time_interval == 'monthly'
      return 'week' if @storage.time_interval == 'weekly'

      raise ArgumentError
    end

    def usage_data
      return [] unless inner_data.values_at(*USAGE_KEYS).any?

      to_chartkick_with_i18n_labels(inner_data.keys.select { |key| USAGE_KEYS.include? key })
    end

    def fraud_data
      to_chartkick_with_i18n_labels(inner_data.keys.select { |key| FRAUD_KEYS.include? key })
    end

    def fraud_redress
      [[I18n.t('reports.count_pending_lg99_likely_fraud'),
        inner_data['count_pending_lg99_likely_fraud']],
       [I18n.t('reports.count_pass_via_lg99'),
        inner_data['count_pass_via_lg99']]]
    end

    def mfa_data
      to_chartkick_with_i18n_labels(inner_data.keys.select { |key| MFA_KEYS.include? key })
    end

    def idv_data
      return [] if inner_data.blank?
      if inner_data['count_newly_proofed_users'].blank? &&
         inner_data['count_preverified_users'].blank?
        return []
      end

      [[I18n.t('reports.count_newly_proofed_users'),
        inner_data['count_newly_proofed_users']],
       [I18n.t('reports.count_preverified_users'),
        inner_data['count_preverified_users']]]
    end

    def data
      to_chartkick_with_i18n_labels(inner_data.keys)
    end

    def grand_total
      return unless inner_data.values_at(*USAGE_KEYS).any?

      USAGE_KEYS.sum { |key| inner_data[key].to_i }
    end

    def fraud_total
      return unless inner_data.values_at(*FRAUD_KEYS).any?

      inner_data.reduce(0) do |sum, (key, value)|
        next sum unless FRAUD_KEYS.include? key

        sum + value.to_i
      end
    end

    def successful_auths
      return unless has_raw_data?

      inner_data['count_auth_successful']
    end

    # Public so the view can check if report data was found
    # and display "Data not available for this month" when it wasn't
    def has_raw_data?
      @raw_data.present? && @raw_data.any?
    end

    def service_provider_name
      provider_information['service_provider_name'].to_s
    end

    # rubocop:disable Rails/Delegate
    def report_information_present?
      report_information.present?
    end
    # rubocop:enable Rails/Delegate

    def formatted_period_start_date
      Date.parse(report_information['period_start_date']).strftime('%Y-%m-%d')
    end

    def period_calendar_id
      report_information['period_calendar_id']
    end

    private

    def provider_information
      return {} unless has_raw_data?

      @provider_information || @raw_data['provider_information']
    end

    def report_information
      return {} unless has_raw_data?

      @report_information || @raw_data['report_information']
    end

    def chosen_date_as_string
      chosen_date.beginning_of_month.strftime('%F')
    end

    def inner_data
      return {} unless has_raw_data?

      @inner_data ||= @raw_data['data'] || {}
    end

    # Unwrap nested arrays from report JSON:
    # [[{hash}]] or [{hash}] -> {hash}
    def unwrap(data)
      data = data[0] while data.is_a?(Array)
      data || {}
    end

    def to_chartkick_with_i18n_labels(keys)
      keys.each_with_object([]) do |key, results|
        next unless I18n.exists?("reports.#{key}")

        label = I18n.t("reports.#{key}")
        results.push([label, inner_data[key]])
      end
    end
  end
end
