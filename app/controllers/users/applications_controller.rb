module Users
  class ApplicationsController < AuthenticatedController

    def index
    end

    def create
      @application = Application.new(application_params)
      application.user = current_user
      validate_and_save_application(:new)
    end

    def update
      authorize application
      application.assign_attributes(application_params)
      validate_and_save_application(:edit)
    end

    def destroy
      authorize application
      application.destroy
      flash[:success] = I18n.t('dashboard.notices.application_deleted', issuer: application.issuer)
      redirect_to users_applications_path
    end

    def new
      @application = Application.new
    end

    def edit
      authorize application
    end

    def show
      authorize application
    end

    private

    def application
      @application ||= Application.find_by(issuer: params[:id])
    end

    def validate_and_save_application(render_on_error)
      if application.valid?
        application.save!
        flash[:success] = I18n.t('dashboard.notices.application_saved', issuer: application.issuer)
        notify_users(application, render_on_error)
        redirect_to users_application_path(application)
      else
        flash[:error] = error_messages
        render render_on_error
      end
    end

    def notify_users(application, render_on_error)
      if render_on_error == :new
        notify_users_new_application(application)
      elsif application.recently_approved?
        notify_users_approved_application(application)
      end
    end

    def notify_users_new_application(application)
      UserMailer.admin_new_application(application).deliver_later
      UserMailer.user_new_application(application).deliver_later
    end

    def notify_users_approved_application(application)
      UserMailer.admin_approved_application(application).deliver_later
      UserMailer.user_approved_application(application).deliver_later
    end

    def error_messages
      [[@errors] + [application.errors.full_messages]].flatten.compact.to_sentence
    end

    def application_params
      params.require(:application).permit(
        :name,
        :description,
        :metadata_url,
        :acs_url,
        :assertion_consumer_logout_service_url,
        :saml_client_cert,
        :block_encryption,
        :active,
        :approved
      )
    end

    helper_method :application
  end
end
