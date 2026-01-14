class SecurityEventsController < ApplicationController # :nodoc:
  before_action -> { authorize SecurityEvent, :manage_security_events? }, only: %i[index all search]
  before_action -> { authorize security_event, :manage_security_events? }, only: %i[show]

  rescue_from ActiveRecord::RecordNotFound do
    render file: 'public/404.html', status: :not_found, layout: false
  end

  def index
    @security_events = current_user.security_events
      .order('issued_at DESC')
      .page(params[:page])

    assign_pagination
  end

  def all
    scope = SecurityEvent.includes(:user)

    if params[:user_uuid].present? && (@user = User.find_by(uuid: params[:user_uuid]))
      scope = scope.where(user_id: @user.id)
    end

    @security_events = scope
      .order('issued_at DESC')
      .page(params[:page])

    assign_pagination
  end

  def show
    @security_event = security_event
  end

  def search
    email = params[:email]

    if email.present?
      if (user = User.find_by(email:))
        redirect_to security_events_all_path(user_uuid: user.uuid)
        return
      else
        flash[:warning] = "Could not find a user with email #{email}"
      end
    end

    redirect_to security_events_all_path
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
