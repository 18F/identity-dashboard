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

  def data_unavailable_or_number_with_delimiter(number)
    return I18n.t('reports.errors.unavailable_data') if number.blank?

    number_with_delimiter(number)
  end

  def data_unavailable_or_show_graph(attributes)
    return I18n.t('reports.errors.unavailable_data') if attributes[:data].blank?

    public_send(attributes[:type], attributes[:data], **attributes[:options])
  end

  private

  def sort_alphabetically(collection, attribute)
    collection.sort_by { |item| item.send(attribute).to_s.downcase }
  end
end
