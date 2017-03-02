module Api
  class ServiceProvidersController < ApplicationController
    before_action(:authenticate_user!, only: [:update]) unless ENV['FORCE_USER']

    def index
      render json: serialized_service_providers(approved_service_providers)
    end

    def update
      if ServiceProviderUpdater.new.ping
        flash[:notice] = I18n.t('notices.service_providers_refreshed')
      else
        flash[:error] = I18n.t('notices.service_providers_refresh_failed')
      end
      redirect_to service_providers_path
    end

    private

    def serialized_service_providers(service_providers)
      ActiveModel::Serializer::CollectionSerializer.new(
        service_providers,
        each_serializer: ServiceProviderSerializer,
      )
    end

    def approved_service_providers
      ServiceProvider.all
    end
  end
end
