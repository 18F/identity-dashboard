module Reports
  # This class presents data for displaying on analytics pages.
  # Its responsibility includes formatting auth funnel data for Chartkick.
  class AuthenticationFunnel
    def initialize(issuer)
    end

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
  end
end
