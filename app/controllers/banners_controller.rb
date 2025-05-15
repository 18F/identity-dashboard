class BannersController < ApplicationController
  before_action -> { authorize Banner, :manage_banners? }
  before_action :set_banner, only: %i[show edit update]
  after_action :verify_authorized
  after_action :verify_policy_scoped

  # GET /banners
  def index
    @banners = policy_scope(Banner.all)
  end

  # GET /banners/new
  def new
    @banner = policy_scope(Banner).new
  end

  # GET /banners/1/edit
  def edit
  end

  # POST /banners
  def create
    @banner = policy_scope(Banner).new(banner_params)

    if @banner.save
      redirect_to banners_path, notice: 'Banner was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /banners/1
  def update
    if @banner.update(banner_params)
      redirect_to banners_path, notice: 'Banner was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_banner
    @banner = policy_scope(Banner).find(params[:id])
  end

    # Only allow a list of trusted parameters through.
  def banner_params
    params.fetch(:banner, {}).permit(:message, :start_date, :end_date)
  end
end
