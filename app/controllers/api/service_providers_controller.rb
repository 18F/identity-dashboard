module Api
  class ServiceProvidersController < ApiController
    def index
      render json: serialized_service_providers(approved_service_providers)
    end

    def show
      render json: ServiceProviderSerializer.new(service_provider, action: :show).as_json
    end

    private

    def serialized_service_providers(service_providers)
      ActiveModel::Serializer::CollectionSerializer.new(
        service_providers,
        each_serializer: ServiceProviderSerializer,
      )
    end

    def approved_service_providers
      ServiceProvider.includes(:agency, logo_file_attachment: :blob).all
    end

    def service_provider
      @service_provider ||= ServiceProvider.includes(:agency, logo_file_attachment: :blob).find(id)
    end

    def id
      @id ||= params[:id]
    end
  end
end
