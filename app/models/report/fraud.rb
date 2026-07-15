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
    ].map { |key| "count_#{key}" }.freeze

    FRAUD_QUEUE_KEYS = ['count_pending_lg99_likely_fraud', 'count_pass_via_lg99'].freeze

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

    def review_queue_chart(chart_options = {})
      {
        type: :bar_chart,
        data: review_queue_data,
        title: 'Redress - Identity Verification',
        options: chart_options.merge({
          subtitle: 'Users who requested redress during this period',
          description: '"Adjudicated as legitimate" reflects cases where ' \
            'Login.gov reviewed the case and reversed the block.',
          # USWDS colors 'orange-warm-40v' and 'green-40v' (for now)
          colors: ['#ff580a', '#719f2a'],
        }),
      }
    end

    private

    def fraud_data
      return [] unless data.values_at(*FRAUD_KEYS).any?

      as_array_with_i18n_labels(data.keys.select { |key| FRAUD_KEYS.include? key })
    end

    def review_queue_data
      return [] unless data.values_at(*FRAUD_QUEUE_KEYS).any?

      as_array_with_i18n_labels(FRAUD_QUEUE_KEYS)
    end
  end
end
