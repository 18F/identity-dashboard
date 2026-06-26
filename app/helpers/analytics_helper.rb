# Helper for Analytics view to handle selection logic
module AnalyticsHelper
  def teams_collection_for_select(teams)
    sort_alphabetically(teams, :name).map do |team|
      {
        name: team.name,
        id: team.id,
        apps: team.uuids_string,
      }
    end
  end

  def service_providers_collection_for_select(sps)
    return [] if sps.blank?

    sort_alphabetically(sps.to_a.flatten, :friendly_name).map do |sp|
      report_id = AnalyticsReportStorage.list(sp.issuer)[0]
      {
        title: sp.friendly_name,
        id: sp.uuid,
        controls: Reports::Identity.available_dates([sp]).uniq,
      }
      # [sp.friendly_name, sp.uuid]
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

  private

  def sort_alphabetically(collection, attribute)
    collection.sort_by { |item| item.send(attribute).to_s.downcase }
  end
end
