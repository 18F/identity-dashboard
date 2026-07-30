module Report
  # Partner reporting for Identity Validation data
  class IdV < Report::Base
    def chart(chart_options = {})
      title = 'Active Identity Verified Users'
      {
        type: :column_chart,
        data: idv_data,
        options: merge_options(chart_options, {
          title: title,
          description: 'Newly proofed are net new users who verified during this window. ' \
            'Previously proofed are users who completed verification ahead of this window,',
          colors: ['#18f'],
          library: {
            accessibility: {
              screenReaderSection: {
                beforeChartFormat: "<h2>#{title}</h2>",
              },
            },
            plotOptions: {
              column: {
                animation: false,
                color_by_point: true,
              },
            },
            subtitle: { text: 'Unique users who accessed a service requiring verification' },
          },
        }),
      }
    end

    private

    def idv_data
      return [] if data.blank?
      if data['count_newly_proofed_users'].blank? && data['count_preverified_users'].blank?
        return []
      end

      [[I18n.t('reports.count_newly_proofed_users'),
        data['count_newly_proofed_users']],
       [I18n.t('reports.count_preverified_users'),
        data['count_preverified_users']]]
    end
  end
end
