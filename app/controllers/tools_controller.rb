class ToolsController < ApplicationController
  require 'saml_idp'

  def saml_request
    @validation_attempted = true

    if params["validation"].blank?
      @validation_attempted = false
      return
    end

    @request = Tools::SAMLRequest.new(validation_params)
    @request.run_validations

    if @request.valid
      @request.xml.write(@xml = '', 2)
    end
  end

  private

  def validation_params
    params.require(:validation).permit(:auth_url, :cert)
  end
end
