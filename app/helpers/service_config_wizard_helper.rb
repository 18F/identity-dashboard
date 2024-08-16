module ServiceConfigWizardHelper
  def wizard_form(&block)
    simple_form_for(@model, url: service_config_wizard_path, method: :put, html: {
      autocomplete: 'off',
      class: 'service-provider-form',
    }) do |form|
      block.call(form)
    end
  end

  def parsed_help_text
    text_params = params.has_key?(@model) ? service_provider_params[:help_text] : nil
    @parsed_help_text ||= HelpText.lookup(
      params: text_params,
      service_provider: @service_provider,
    )
  end
end
