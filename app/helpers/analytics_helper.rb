# Helper for charts in Analytics views

module AnalyticsHelper
  def chart_canvas(chart_id, type:, labels:, datasets:)
    config = {
      type:,
      data: { labels:, datasets: },
      options: { responsive: true, animation: false, plugins: { legend: { position: 'bottom' } } },
    }
    content_tag :canvas, '',
      id: chart_id,
      class: 'analytics-chart',
      data: { config: config.to_json }
  end

  def readable_header
    {
      active_users: 'Total Active Users',
      fraudsters_blocked: 'Fraudsters Blocked',
      newly_created_accounts: 'Newly Created Accounts',
      existing_accounts: 'Existing Accounts',
      identity_verified_users: 'Total Identity Verified Users',
      newly_proofed_users: 'Newly Proofed Users',
      preverified_users: 'Preverified Users',
      authentications: 'Authentications',
      fraud_users_account_creation: 'Account creation fraud',
      fraud_users_inauthentic_doc: 'Inauthentic/fraudulent documents',
      fraud_users_facial_mismatch: 'Facial recognition mismatch',
      fraud_users_invalid_attributes_dl_dos: "Invalid driver's license or DOS attributes",
      fraud_users_ssn_dob_deceased: 'SSN/DOB indicates deceased person',
      fraud_users_address_other_not_found: 'Address fraud or other indicators',
      raud_users_fraud_alert: 'Fraud alert trigger during identity resolution',
      fraud_users_suspicious_phone: 'Suspicious phone number during address verification',
      fraud_users_lack_phone_ownership: 'Inability to verify phone ownership during address verification',
      fraud_users_wrong_phone_type: 'Wrong phone type during address verification',
      fraud_users_stayed_blocked: 'Users who remained blocked due to fraud after handoff',
      fraud_users_blocked_for_fraud: 'Users blocked for fraud after failing fraud review',
    }.with_indifferent_access
  end
end
