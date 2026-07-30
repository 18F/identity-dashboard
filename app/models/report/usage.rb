module Report
  # Partner reporting for general usage not covered in other classes
  class Usage < Report::Base
    USAGE_KEYS = %w[
      count_newly_created_accounts
      count_existing_accounts
    ].freeze

    def total
      return unless data.values_at(*USAGE_KEYS).any?

      USAGE_KEYS.sum { |key| data[key].to_i }
    end

    def successful_auths
      return unless data['count_auth_successful'].present?

      data['count_auth_successful']
    end

    def chart(chart_options = {})
      title = 'All Active Users'
      {
        type: :column_chart,
        data: usage_data,
        options: merge_options(chart_options, {
          title: title,
          description: 'New accounts reflect account creation during this window. ' \
            'Existing accounts reflect accounts created ahead of this window.',
          colors: ['#18f'],
          library: {
            accessibility: {
              screenReaderSection: {
                beforeChartFormat: "<h2>#{title}</h2>",
              },
            },
            plotOptions: {
              column:
                {
                  animation: false,
                  color_by_point: true,
                },
            },
            subtitle: { text: 'Unique users who accessed a service' },
          },
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
