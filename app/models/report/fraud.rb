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
  end
end
