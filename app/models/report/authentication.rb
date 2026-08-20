module Report
  # Partner reporting for authentication statistics
  # This class converts ratio floats to rounded percentages
  class Authentication < Base
    # Types of MFE used — `webauthn_platform` is face/touch and
    # `webauthn` is a security key that isn't face/touch
    MFA_PERCENTAGES = %w[
      pct_webauthn_platform_of_auth
      pct_totp_of_auth
      pct_piv_cac_of_auth
      pct_sms_of_auth
      pct_voice_of_auth
      pct_backup_code_of_auth
      pct_webauthn_of_auth
      pct_personal_key_of_auth
    ].freeze

    DEVICE_PERCENTAGES = %w[
      pct_mobile_of_auth
      pct_desktop_of_auth
    ].freeze

    def success_rate
      return nil unless data['pct_authentication_success']

      rounded_percentage(data['pct_authentication_success'])
    end

    def account_creation_success_rate
      return nil unless data['pct_account_creation_success']

      rounded_percentage(data['pct_account_creation_success'])
    end

    def mfa_chart
      {
        type: :bar_chart,
        data: mfa_type_data,
        options: merge_options(
          title: 'Multi-Factor Authentication (MFA) Type',
          subtitle: 'How users authenticated during this window',
          description: 'Percentage of successful sign-ins from MFA type, ' \
            'out of all successful attempts',
          max: 100,
          suffix: '%',
        ),
      }
    end

    def device_type_chart
      {
        type: :pie_chart,
        data: device_type_data,
        options: merge_options({
          title: 'Device Type',
          subtitle: 'How users accessed your service during this window',
          description:
            'Percentage of successful sign-ins from device type, out of all successful attempts.',
          colors: ['#18f', '#e21c3d', '#f09436', '#40892d'],
          donut: true,
          suffix: '%',
        }),
      }
    end

    private

    def mfa_type_data
      return [] unless data.values_at(*MFA_PERCENTAGES).any?

      mfa_ratios = as_array_with_i18n_labels(MFA_PERCENTAGES.select { |key| data.key?(key) })
      # Turn ratios into rounded percentages
      mfa_ratios.map { |(key, value)| [key, rounded_percentage(value)] }
    end

    def device_type_data
      return [] unless data.values_at(*DEVICE_PERCENTAGES).any?

      device_ratios = as_array_with_i18n_labels(DEVICE_PERCENTAGES.select { |key| data.key?(key) })
      # Turn ratios into rounded percentages
      device_ratios.map { |(key, value)| [key, rounded_percentage(value)] }
    end
  end
end
