# Helper for Analytics view to handle selection logic
module AnalyticsHelper
  def teams_collection_for_select(teams)
    teams.filter_map do |team|
      if uuid_list(team).present?
        {
          name: team.name,
          id: team.id,
          apps: uuid_list(team),
        }
      end
    end
  end

  def uuid_list(team)
    return '' if team.blank?

    team.service_providers.map(&:uuid).join(',')
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
end
