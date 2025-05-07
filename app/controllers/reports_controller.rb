class ReportsController < AuthenticatedController
  before_action :admin_only

  # GET /reports
  def index
    @memberships = UserTeam.joins('right outer join users on user_groups.user_id = users.id')
      .select('users.id as user_id, user_groups.group_id, user_groups.role_name')
      .includes(:role)
      .order('users.email', 'roles.id')
  end

  # # GET /reports/1
  # def show
  # end

  # # GET /reports/new
  # def new
  #   @report = Report.new
  # end

  # # GET /reports/1/edit
  # def edit
  # end

  # # POST /reports
  # def create
  #   @report = Report.new(report_params)

  #   if @report.save
  #     redirect_to @report, notice: "Report was successfully created."
  #   else
  #     render :new, status: :unprocessable_entity
  #   end
  # end

  # # PATCH/PUT /reports/1
  # def update
  #   if @report.update(report_params)
  #     redirect_to @report, notice: "Report was successfully updated.", status: :see_other
  #   else
  #     render :edit, status: :unprocessable_entity
  #   end
  # end

  # # DELETE /reports/1
  # def destroy
  #   @report.destroy!
  #   redirect_to reports_url, notice: "Report was successfully destroyed.", status: :see_other
  # end

  private

  def admin_only
    raise ActionNotFound unless current_user.logingov_admin?
  end
end
