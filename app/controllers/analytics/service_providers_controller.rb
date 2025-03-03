class Analytics::ServiceProvidersController < ApplicationController
    def show
       @issuer = service_provider.issuer
    end

    private

    def service_provider
        @service_provider ||= ServiceProvider.includes(:agency, logo_file_attachment: :blob).find(id)
    end

    def id
        @id ||= params[:id]
    end
end

  