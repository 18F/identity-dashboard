class Reports
  # Partner reporting for Identity Validation data
  class IdV < Reports::Base
    def idv_data
      return [] if data.blank?
      return [] if data['count_newly_proofed_users'].blank? && ['count_preverified_users'].blank?

      [[I18n.t('reports.count_newly_proofed_users'),
        data['count_newly_proofed_users']],
       [I18n.t('reports.count_preverified_users'),
        data['count_preverified_users']]]
    end
  end
end
