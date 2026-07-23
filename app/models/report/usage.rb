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

    def chart(chart_options = {})
      {
        type: :column_chart,
        data: usage_data,
        title: 'All Active Users',
        options: chart_options.merge({
          subtitle: 'Unique users who accessed a service',
          description: 'New accounts reflect account creation during this window. ' \
            'Existing accounts reflect accounts created ahead of this window.',
        }),
      }
    end

    private

    def usage_data
      return [] unless data.values_at(*USAGE_KEYS).any?

      as_array_with_i18n_labels(data.keys.select { |key| USAGE_KEYS.include? key })
    end
  end
end
