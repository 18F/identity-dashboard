module Report
  # Partner reporting for fraud statistics
  class Fraud < Base
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

    def total
      return unless data.values_at(*FRAUD_KEYS).any?

      data.reduce(0) do |sum, (key, value)|
        next sum unless FRAUD_KEYS.include? key

        sum + value.to_i
      end
    end

    def chart(chart_options = {})
      {
        type: :bar_chart,
        data: fraud_data,
        title: 'Fraudsters Blocks',
        options: chart_options.merge({
          subtitle: 'Users blocked per outcome type',
        }),
      }
    end

    private

    def fraud_data
      return [] unless data.values_at(*FRAUD_KEYS).any?

      as_array_with_i18n_labels(data.keys.select { |key| FRAUD_KEYS.include? key })
    end
  end
end
