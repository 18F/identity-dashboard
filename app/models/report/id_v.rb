module Report
  # Partner reporting for Identity Validation data
  class IdV < Report::Base
    FRICTION_POINT_KEYS = %w[
      blocked_document_upload_ux
      selfie_ux
      identity_resolution_attribute_mismatch
      phone_number_record_check_failure
      temporary_technical_issues
    ].map { |key| "count_#{key}" }.freeze

    VERIFICATION_CHANNEL_KEYS = %w[
      pass_online_finalization
      skip_preverified_finalization
      pass_ipp
      pass_via_letter
    ].map { |key| "count_#{key}" }.freeze

    def proofing_success_chart
      {
        type: :pie_chart,
        data: proofing_success_data,
        options: merge_options({
          title: 'Proofing Success Rate',
          subtitle: 'Percentage of users who were successfully redirected to the application ' \
            'during this window',
          description: 'Percentage of users who successfully completed identity verification ' \
            'credentials out of total users attempting, controlling for fraud and abandonment.',
          colors: ['#18f', '#e21c3d'],
          donut: true,
          suffix: '%',
        }),
      }
    end

    def access_path_chart
      {
        type: :bar_chart,
        data: access_path_data,
        options: merge_options({
          title: 'Path to Access Rate',
          subtitle: 'Percentage of users who attempted verification, how many had a way forward ' \
            'during this window',
          description: 'This is counting 1 - (users who dead-ended / users who attempted). It ' \
            "shows, out of all users who attempted, who weren't dead-ended.",
          stacked: true,
          max: 100,
          suffix: '%',
          colors: ['#e21c3d', '#18f'],
          library: {
            plotOptions: {
              series: {
                animation: false,
                colorByPoint: false,
              },
            },
          },
        }),
      }
    end

    def channels_chart
      {
        type: :pie_chart,
        data: channels_data,
        options: merge_options({
          title: 'Identity Verification Channels',
          subtitle: 'How users verified their identity during this window',
          description: 'Channels through which users verified their identity credentials. ' \
            'Preverified = A user created a verification profile (passed proofing) elsewhere ' \
            'prior to this window. Remote unattended = Users who went through the online ' \
            'proofing process. IPP = users who completed their proofing process through in ' \
            'person verification. Physical letter = users who completed their address ' \
            'verification through receiving a letter from the Post Office.',
          colors: ['#18f', '#e21c3d', '#f09436', '#40892d'],
          donut: true,
          suffix: '%',
        }),
      }
    end

    def friction_chart
      {
        type: :bar_chart,
        data: friction_data,
        options: merge_options({
          title: 'Points of User Friction',
          subtitle: 'Where users experienced the most difficulty completing verification during ' \
            'this window',
          description: 'Counts represent users who hit given friction points across document ' \
            'authentication, identity resolution, and address verification steps and did not ' \
            'get past the block in the reporting window.',
          colors: ['#18f', '#e21c3d'],
        }),
      }
    end

    private

    def proofing_success_data
      return [] unless data['pct_proofing_success'].present? &&
                       data['pct_proofing_success'].positive?

      [
        ['Pass', rounded_percentage(data['pct_proofing_success'])],
        ['Not Pass', rounded_percentage(1.0 - data['pct_proofing_success'])],
      ]
    end

    def access_path_data
      return [] unless data['pct_path_to_access'].present? &&
                       data['pct_path_to_access'].positive?

      [
        { name: 'Dead End',
          data: [['', rounded_percentage(1 - data['pct_path_to_access'])]] },
        { name: 'Path Forward',
          data: [['', rounded_percentage(data['pct_path_to_access'])]] },
      ]
    end

    def channels_data
      return [] unless data.values_at(*VERIFICATION_CHANNEL_KEYS).any?

      total = data.values_at(*VERIFICATION_CHANNEL_KEYS).filter { |val| val }.sum
      verification_channels = as_array_with_i18n_labels(
        VERIFICATION_CHANNEL_KEYS.select { |key| data.key?(key) },
      )
      # Turn integers into rounded percentages
      verification_channels.map { |(key, value)| [key, divide_and_round(value, total)] }
    end

    def friction_data
      return [] unless data.values_at(*FRICTION_POINT_KEYS).any?

      friction_points = as_array_with_i18n_labels(
        FRICTION_POINT_KEYS.select { |key| data.key?(key) },
      )
      friction_points.to_a
    end

    def divide_and_round(numerator, denominator)
      return 0 unless numerator && denominator.positive?

      rounded_percentage(numerator / denominator.to_f)
    end
  end
end
