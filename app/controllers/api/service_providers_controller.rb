module Api
  class ServiceProvidersController < ApplicationController
    def index
      render json: serialized_service_providers(approved_service_providers)
    end

    private

    def serialized_service_providers(service_providers)
      ActiveModel::Serializer::CollectionSerializer.new(
        service_providers,
        each_serializer: ServiceProviderSerializer
      )
    end

    def approved_service_providers
      ServiceProvider.where(active: true, approved: true)
    end
  end
end
