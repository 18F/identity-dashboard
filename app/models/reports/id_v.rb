class Reports
  # Partner reporting for Identity Validation data
  class IdV < Reports::Base
    def chart(chart_options = {})
      {
        type: :column_chart,
        data: idv_data,
        title: 'Active Identity Verified Users',
        options: chart_options.merge({
          subtitle: 'Unique users who accessed a service requiring verification',
          description: 'Newly proofed are net new users who verified during this window. ' \
            'Previously proofed are users who completed verification ahead of this window,',
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
