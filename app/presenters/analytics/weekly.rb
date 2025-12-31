module Analytics
  # Weekly presenter for service provider weekly analytics data
  class Weekly
    FRAUD_BLOCKS = %w[
      fraud_users_account_creation
      fraud_users_inauthentic_doc
      fraud_users_facial_mismatch
      fraud_users_invalid_attributes_dl_dos
      fraud_users_ssn_dob_deceased
      fraud_users_address_other_not_found
    ]

    FRAUD_ALERTS = %w[
      fraud_users_fraud_alert
      fraud_users_suspicious_phone
      fraud_users_lack_phone_ownership
      fraud_users_wrong_phone_type
    ]

    FRAUD_INVESTIGTION = %w[
      fraud_users_stayed_blocked
      fraud_users_blocked_for_fraud
    ]

    TOPLINE_DATA = %w[
      active_users
      fraudsters_blocked
    ]

    USAGE_DATA = %w[
      newly_created_accounts
      existing_accounts
      identity_verified_users
      newly_proofed_users
      preverified_users
      authentications
    ]

    attr_reader :fiscal_year,
      :date,
      :topline_data,
      :usage_data,
      :fraud_blocks,
      :fraud_alerts,
      :fraud_investigation

    def initialize(csv_row)
      @fiscal_year = csv_row['fiscal_year']
      @date = Date.parse(csv_row['week_start_date_actual'])

      @topline_data = csv_row.slice(*TOPLINE_DATA)
      @usage_data = csv_row.slice(*USAGE_DATA)
      @fraud_blocks = csv_row.slice(*FRAUD_BLOCKS)
      @fraud_alerts = csv_row.slice(*FRAUD_ALERTS)
      @fraud_investigation = csv_row.slice(*FRAUD_INVESTIGTION)
    end
  end
end
