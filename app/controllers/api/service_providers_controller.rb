module Api
  class ServiceProvidersController < ApplicationController
    before_action(:authenticate_user!, only: [:update]) unless ENV['FORCE_USER']

    def index
      render json: serialized_service_providers(approved_service_providers)
    end

    def update
      ServiceProviderUpdater.new.delay.ping
      flash[:notice] = I18n.t('notices.service_providers_refreshed')
      redirect_to users_service_providers_path
    end

    private

    def serialized_service_providers(service_providers)
      ActiveModel::Serializer::CollectionSerializer.new(
        service_providers,
        each_serializer: ServiceProviderSerializer
      )
    end

    def approved_service_providers
      ServiceProvider.where(active: true)
    end
  end
end
