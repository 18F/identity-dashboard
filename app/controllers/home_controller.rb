require 'portal/constants'
# Controller for the Home pages (logged-in and out)
class HomeController < ApplicationController
  def index
    @canonical_url = user_signed_in? ? nil : request.base_url.gsub('portal', 'dashboard')
    unless user_signed_in?
      @available_reports = available_reports
      render :index and return
    end

    signed_in_redirect
  end

  def system_use
    render 'home/system_use' and return unless user_signed_in?

    signed_in_redirect
  end

  private

  def available_reports
    AnalyticsReportStorage.list
      .select { |f| f.key.end_with?('.json') }
      .sort_by(&:last_modified)
      .reverse
  end

  def signed_in_redirect
    includes = %i[users service_providers agency]
    @teams = current_user.teams.includes(*includes).all

    render 'home/authenticated/index'
  end
end
