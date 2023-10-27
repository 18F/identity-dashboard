class ToolsController < ApplicationController
  require 'saml_idp'

  def saml_request
    flash[:warning] = nil
    @validation_attempted = true

    if params['validation'].blank?
      @validation_attempted = false
      return
    end

    @request = Tools::SAMLRequest.new(validation_params)

    if @request.logout_request?
      flash[:warning] = 'You have passed a logout request. Currently, this tool is for ' +
                        'Authentication requests only.'
      @validation_attempted = false
      return
    end

    @request.run_validations

    @request.xml.write(@xml = '', 2) if @request.valid
  end

  private

  def validation_params
    params.require(:validation).permit(:auth_url, :cert)
  end
end
