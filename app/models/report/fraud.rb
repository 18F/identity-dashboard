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
      # Only explain the "adjudicated" column if we have data
      if review_queue_data.present?
        chart_options = chart_options.merge(description:
          '"Adjudicated as legitimate" reflects cases where ' \
            'Login.gov reviewed the case and reversed the block.')
      end
      {
        type: :bar_chart,
        data: review_queue_data,
        title: 'Redress – Identity Verification',
        options: chart_options.merge({
          subtitle: 'Users who requested redress during this period',
          # USWDS colors 'orange-warm-40v' and 'green-40v' (for now)
          colors: ['#ff580a', '#719f2a'],
        }),
      }
    end

    private

    def fraud_data
      return [] unless data.values_at(*FRAUD_KEYS).any?

      # This chart has lots of categories, so we don't want to show categories that have no data
      as_array_with_i18n_labels(FRAUD_KEYS.select { |key| data.key?(key) })
    end

    def review_queue_data
      return [] unless data.values_at(*FRAUD_QUEUE_KEYS).all?

      # This chart has only two categories, so we want to show a blank category as being zero
      # even if we have no data for it
      as_array_with_i18n_labels(FRAUD_QUEUE_KEYS)
    end
  end
end
