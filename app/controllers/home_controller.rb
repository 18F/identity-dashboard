require 'portal/constants'

class HomeController < ApplicationController
  def index
    @canonical_url = (!user_signed_in?) ? request.base_url.gsub('portal', 'dashboard') : nil
    render :index and return unless user_signed_in?

    includes = %i[users service_providers agency]
    @teams = current_user.teams.includes(*includes).all

    render 'home/authenticated/index'
  end

  def system_use
    render 'home/system_use' and return unless user_signed_in?

    render 'home/authenticated/index'
  end
end
