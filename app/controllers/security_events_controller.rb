class SecurityEventsController < ApplicationController
  before_action -> { authorize SecurityEvent }, only: %i[index all]
  before_action -> { authorize security_event }, only: %i[show]

  rescue_from ActiveRecord::RecordNotFound do
    render file: 'public/404.html', status: :not_found, layout: false
  end

  def index
    @security_events = current_user.security_events.
                       order('issued_at DESC').
                       page(params[:page])

    assign_pagination
  end

  def all
    @security_events = SecurityEvent.includes(:user).
                       order('issued_at DESC').
                       page(params[:page])

    assign_pagination
  end

  def show
    @security_event = security_event
  end

  private

  def security_event
    @security_event ||= SecurityEvent.find(params[:id])
  end

  def assign_pagination
    @prev_page = @security_events.prev_page && url_for(page: @security_events.prev_page)
    @next_page = @security_events.next_page && url_for(page: @security_events.next_page)
  end
end
