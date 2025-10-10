class ToolsController < AuthenticatedController # :nodoc:
  require 'saml_idp'

  def saml_request
  end

  def validate_saml_request
    flash[:warning] = nil
    @validation_attempted = true

    @request = Tools::SamlRequest.new(validation_params)

    if @request.logout_request?
      flash[:warning] = 'You have passed a logout request. Currently, this tool is for ' \
                        'Authentication requests only. Please try this ' \
                        '<a href="https://www.samltool.com/validate_logout_req.php" ' \
                        'target="_blank">tool</a> to validate logout requests.'

      @validation_attempted = false
      render 'saml_request' and return
    end

    @request.run_validations

    render 'saml_request'
  end

  private

  def validation_params
    params.require(:validation).permit(:auth_url, :cert)
  end
end
