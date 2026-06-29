# Helper for Analytics view to handle selection logic
module AnalyticsHelper
  def teams_collection_for_select(teams)
    sort_alphabetically(teams, :name).map do |team|
      {
        title: team.name,
        id: team.id,
        controls: team.uuids_string,
      }
    end
  end

  def service_providers_collection_for_select(sps)
    return [] if sps.blank?

    all_available_dates = Reports::Identity.available_dates(sps, current_user)
    sort_alphabetically(sps.to_a.flatten, :friendly_name).map do |sp|
      {
        title: sp.friendly_name,
        id: sp.uuid,
        controls: all_available_dates[sp.issuer]&.uniq&.join(','),
      }
    end
  end

  def dates_collection_for_select(dates)
    return [] if dates.blank?

    dates.sort.map do |date|
      {
        title: date,
        id: date,
        controls: '',
      }
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

  def permitted_teams(user)
    teams = user.scoped_teams.filter do |team|
      team.service_providers.present?
    end
    return teams if user.logingov_staff?

    user.team_memberships.where(role: 'partner_admin', team: [teams]).map(&:team)
  end

  private

  def sort_alphabetically(collection, attribute)
    collection.sort_by { |item| item.send(attribute).to_s.downcase }
  end
end
