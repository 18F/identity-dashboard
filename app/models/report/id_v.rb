module Report
  # Partner reporting for Identity Validation data
  class IdV < Report::Base
    FRICTION_POINT_KEYS = %w[
      blocked_document_upload_ux
      selfie_ux
      identity_resolution_atribute_mismatch
      phone_number_record_check_failure
      temporary_technical_issues
    ].map { |key| "count_#{key}" }.freeze

    VERIFICATION_CHANNEL_KEYS = %w[
      skip_preverified_finalization
      pass_online_finalization
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
          description: 'This is counting  1 - (users who dead-ended / users who attempted). It ' \
            "shows, out of all users who attempted, who weren't dead-ended.",
          colors: ['#18f', '#e21c3d'],
          library: {
            plotOptions: { series: { stacking: 'percent' } },
            series: [{
              dataMapping: { y: 'Path Forward' },
            }, {
              dataMapping: { y: 'Dead End' },
            }],
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
      return [] unless data.values_at('pct_proofing_success').any?

      [
        ['Pass', data['pct_proofing_success']],
        ['Not Pass', 1.0 - data['pct_proofing_success']],
      ]
    end

    def access_path_data
      return [] unless data.values_at('pct_path_to_access').any?

      [
        ['Path Forward', data['pct_path_to_access']],
        ['Dead End', 1 - data['pct_path_to_access']],
      ]
    end

    def channels_data
      return [] unless data.values_at(*VERIFICATION_CHANNEL_KEYS).any?

      total = data.values_at(*VERIFICATION_CHANNEL_KEYS).filter { |key| key }.sum
      [
        ['Remote Unattended', divide_and_round('count_pass_online_finalization', total)],
        ['Preverified', divide_and_round('count_skip_preverified_finalization', total)],
        ['In-Person Proofing', divide_and_round('count_pass_ipp', total)],
        ['Physical Letter', divide_and_round('count_pass_via_letter', total)],
      ]
    end

    def friction_data
      return [] unless data.values_at(*FRICTION_POINT_KEYS).any?

      [
        ['Document Upload UX', data['count_blocked_docuemnt_upload_ux']],
        ['Selfie UX Issue', data['count_selfie_ux']],
        ['Identity Resolution Attribute Mismatch',
         data['count_identity_resolution_attribute_mismatch']],
        ['Phone Number Record Check Failure',
         data['count_phone_number_record_check_failure']],
        ['Temporary Technical Issue', data['count_temporary_technical_issue']],
      ]
    end

    def divide_and_round(numerator, denominator)
      (data[numerator] / denominator.to_f).round(4)
    end
  end
end
