class ServiceProviderLogosController < AuthenticatedController
  def show
    logo_file = service_provider.logo_file
    return render(plain: 'Not Found', status: :not_found) unless logo_file.attached?
    send_data(
      logo_file.download,
      type: logo_file.content_type,
      disposition: :inline
    )
  end

  private

  def service_provider
    @service_provider ||= ServiceProvider.find(params[:id])
  end
end
