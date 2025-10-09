module Api
  # Controller for SecurityEvents API
  class SecurityEventsController < ApplicationController
    skip_forgery_protection

    def create
      form = SecurityEventForm.new(body: request.body.read)
      success, errors = form.submit

      if success
        head :created
      else
        Rails.logger.warn(errors.to_hash)

        head :bad_request
      end
    end
  end
end
