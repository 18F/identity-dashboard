module Report
  # Partner reporting for general usage not covered in other classes
  class Usage < Report::Base
    USAGE_KEYS = %w[
      count_newly_created_accounts
      count_existing_accounts
    ].freeze

    def total
      data['count_active_users'].presence
    end

    def successful_auths
      data['count_auth_successful'].presence
    end

    def idv_chart
      {
        type: :column_chart,
        data: idv_data,
        options: merge_options({
          title: 'Active Identity Verified Users',
          subtitle: 'Unique users who accessed a service requiring verification',
          description: 'Newly proofed are net new users who verified during this window. ' \
            'Previously proofed are users who completed verification ahead of this window,',
          colors: ['#18f'],
        }),
      }
    end

    def overall_chart
      {
        type: :column_chart,
        data: usage_data,
        options: merge_options({
          title: 'All Active Users',
          subtitle: 'Unique users who accessed a service',
          description: 'New accounts reflect account creation during this window. ' \
            'Existing accounts reflect accounts created ahead of this window.',
          colors: ['#18f'],
        }),
      }
    end

    private

    def idv_data
      if data.blank? ||
         (data['count_newly_proofed_users'].blank? && data['count_preverified_users'].blank?)
        return []
      end

      [[I18n.t('reports.count_newly_proofed_users'),
        data['count_newly_proofed_users']],
       [I18n.t('reports.count_preverified_users'),
        data['count_preverified_users']]]
    end

    def usage_data
      return [] unless data.values_at(*USAGE_KEYS).any?

      as_array_with_i18n_labels(data.keys.select { |key| USAGE_KEYS.include? key })
    end
  end
end
