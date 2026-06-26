class Reports
  # Partner reporting for general usage not covered in other classes
  class Usage < Reports::Base
    USAGE_KEYS = %w[
      count_newly_created_accounts
      count_existing_accounts
    ].freeze

    def grand_total
      return unless data.values_at(*USAGE_KEYS).any?

      USAGE_KEYS.sum { |key| data[key].to_i }
    end

    def successful_auths
      return unless data['count_auth_successful'].present?

      data['count_auth_successful']
    end

    def chart(chart_options = {})
      {
        type: :column_chart,
        data: usage_data,
        title: 'All Active Users',
        options: chart_options.merge({
          top_description: 'Unique users who accessed a service',
          bottom_description: 'New accounts reflect account creation during this window. ' \
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
