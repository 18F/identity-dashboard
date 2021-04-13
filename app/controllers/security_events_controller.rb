class SecurityEventsController < ApplicationController
  before_action -> { authorize SecurityEvent }, only: %i[index all]

  def index
    @security_events = current_user.security_events.
                                    order('issued_at DESC').
                                    page(params[:page])

    if @security_events.out_of_range?
      redirect_to security_events_path
    else
      assign_pagination
    end
  end

  def all
    @security_events = SecurityEvent.includes(:user).
                                     order('issued_at DESC')
                                     page(params[:page])

    if @security_events.out_of_range?
      redirect_to security_events_all_path
    else
      assign_pagination
    end
  end

  private

  def assign_pagination
    @prev_page = @security_events.prev_page && url_for(page: @security_events.prev_page)
    @next_page = @security_events.next_page && url_for(page: @security_events.next_page)
  end
end
