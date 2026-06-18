# Helper for Analytics view to handle selection logic
module AnalyticsHelper
  def teams_collection_for_select(teams)
    teams.filter_map do |team|
      if team.uuids_string.present?
        {
          name: team.name,
          id: team.id,
          apps: team.uuids_string,
        }
      end
    end
  end

  def service_providers_collection_for_select(sps)
    return [] if sps.blank?

    sps.to_a.flatten.map do |sp|
      [sp.friendly_name, sp.uuid]
    end
  end

  def selected_date_range(date)
    return 'No date range selected' if date.blank?

    end_date = Date.parse(date).end_of_month
    "#{date} to #{end_date.strftime('%F')}"
  end

  def all_app_options_string(teams)
    return '' if teams.blank?

    teams.map(&:uuids_string).join(',')
  end
end
