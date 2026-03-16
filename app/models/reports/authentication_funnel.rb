module Reports
  # This class presents data for displaying on analytics pages.
  # Its responsibility includes formatting auth funnel data for Chartkick.
  class AuthenticationFunnel
    def initialize(issuer)
      # TODO: make data depend on issuer
    end

    # TODO: delete all the below methods and replace with methods that use data from the bucket
    # TODO: reduce number of methods. We don't need all of these. They're just for demonstration.
    # Each report class should only care about one category of data, and we should only have
    # multiple methods if we want different ways of displaying the same data (e.g. pivots of stacked
    # charts)
    def summary_data
      {
        'Timeframe' => DateTime.parse('2026-03-02Z00:00')...DateTime.parse('2026-03-09Z00:00'),
        'Data Generated' => Date.parse('2026-03-09'),
        'Issuer' => issuer,
        'Total # of IAL1 Users' => 4015,
      }
    end

    def data
      [
        ['New Users Started IAL1 Verification', 136],
        ['New Users Completed IAL1 Password Setup', 135],
        ['New Users Completed IAL1 MFA', 133],
        ['New IAL1 Users Consented to Partner', 91],
      ]
    end

    def dramatic_data
      [
        ['New Users Started IAL1 Verification', 9600],
        ['New Users Completed IAL1 Password Setup', 135],
        ['New Users Completed IAL1 MFA', 133],
        ['New IAL1 Users Consented to Partner', 1],
      ]
    end

    def detailed_data
      [
        {
          name: 'Real data', data: {
            'New Users Started IAL1 Verification' => 136,
            'New Users Completed IAL1 Password Setup' => 135,
            'New Users Completed IAL1 MFA' => 133,
            'New IAL1 Users Consented to Partner' => 91,
          }
        },
        {
          name: 'Fake data', data: {
            'New Users Started IAL1 Verification' => 600,
            'New Users Completed IAL1 Password Setup' => 135,
            'New Users Completed IAL1 MFA' => 133,
            'New IAL1 Users Consented to Partner' => 1,
          }
        },
      ]
    end

    def stacked_data
      [
        {
          name: 'December', data: {
            count_pass_online_finalization: 22_330,
            count_suspicious_phone: 1567,
            count_lack_phone_ownership: 1288,
            count_invalid_attributes_dl_dos: 500,
            count_inauthentic_doc: 475,
            count_pass_ipp_online_portion: 319,
            count_wrong_phone_type: 317,
            count_ssn_incorrect: 186,
            count_address_other_not_found: 163,
            count_facial_mismatch: 82,
            count_dob_incorrect: 65,
            count_friction_during_otp: 59,
            count_selfie_ux: 54,
            count_stayed_blocked: 27,
            count_pending_lg99_likely_fraud: 24,
            count_pass_via_lg99: 22,
            count_ssn_dob_deceased: 12,
            count_identity_not_found: 6,
            count_fraud_alert: 2,
            count_doc_auth_processing_issue: 2,
            count_blocked_by_ipp_fraud: 0,
            count_pass_via_letter: 0,
            count_doc_auth_ux: 0,
            count_doc_auth_technical_issue: 0,
            count_resolution_technical_issues: 0,
          }
        },
        {
          name: 'January', data: {
            count_pass_online_finalization: 16_368,
            count_lack_phone_ownership: 505,
            count_suspicious_phone: 484,
            count_invalid_attributes_dl_dos: 423,
            count_pass_ipp_online_portion: 317,
            count_wrong_phone_type: 290,
            count_inauthentic_doc: 151,
            count_ssn_incorrect: 79,
            count_stayed_blocked: 71,
            count_address_other_not_found: 55,
            count_pass_via_lg99: 49,
            count_dob_incorrect: 40,
            count_ssn_dob_deceased: 36,
            count_friction_during_otp: 26,
            count_pending_lg99_likely_fraud: 24,
            count_facial_mismatch: 19,
            count_selfie_ux: 16,
            count_pass_via_letter: 5,
            count_identity_not_found: 4,
            count_fraud_alert: 2,
            count_blocked_by_ipp_fraud: 0,
            count_doc_auth_ux: 0,
            count_doc_auth_technical_issue: 0,
            count_resolution_technical_issues: 0,
            count_doc_auth_processing_issue: 0,
          }
        },
      ]
    end
  end
end
