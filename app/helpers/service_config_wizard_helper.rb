module ServiceConfigWizardHelper
  def wizard_form(&block)
    simple_form_for(@model, url: service_config_wizard_path, method: :put, html: {
      autocomplete: 'off',
      class: 'service-provider-form',
    }) do |form|
      block.call(form)
    end
  end

  def accessible_label(form, label, db_form_field)
    message = form.object ? form.object.errors.messages_for(db_form_field)[0] : nil
    if message.present?
      ("#{label}<p class='usa-sr-only'>, Error:
        #{
          form.object.errors.messages_for(db_form_field)[0] || ''
        }</p>").html_safe
    else
      label
    end
  end

  def view_parsed_help_text
    text_params = params.has_key?(@model) ? wizard_step_params[:help_text] : nil
    @parsed_help_text ||= HelpText.lookup(
      params: text_params,
      service_provider: @service_provider || draft_service_provider,
    )
  end

  def view_custom_help_text
    @custom_help_text ||= HelpText.lookup(
      service_provider: @service_provider || draft_service_provider,
    )
  end

  def first_step?
    step.eql?(wizard_steps.first)
  end

  def no_data?
    first_step? || (
      step.eql?('issuer') && @model.existing_service_provider?
    )
  end

  def last_step?
    step.eql? wizard_steps.last
  end

  def last_step_message
    i18n_key = @model.existing_service_provider? ? 'save_existing' : 'save_new'
    t("service_provider_form.#{i18n_key}")
  end

  def show_cancel?
    IdentityConfig.store.service_config_wizard_enabled && current_user.logingov_admin?
  end

  def readonly_help_text?
    !service_provider_policy.edit_custom_help_text?
  end

  def help_text_options_available?
    feature_enabled = IdentityConfig.store.help_text_options_feature_enabled
    options_enabled = feature_enabled && !current_user.logingov_admin?
    text_info = view_parsed_help_text
    has_no_custom = text_info.blank? || text_info.presets_only?

    options_enabled && has_no_custom
  end
end
