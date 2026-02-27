class HelpTextPresenter
  attr_reader :current_user, :help_text

  def initialize(help_text, current_user)
    @help_text = help_text
    @current_user = current_user
  end

  delegate :edit_custom_help_text?, to: :service_provider_policy

  def readonly_help_text?
    !edit_custom_help_text?
  end

  def help_text_options_available?
    options_enabled = !edit_custom_help_text?
    has_no_custom = help_text.blank? || help_text.presets_only?

    options_enabled && has_no_custom
  end

  def show_minimal_help_text_element?
    return false if service_provider_policy.edit_custom_help_text?

    help_text.blank? || help_text.presets_only?
  end

  def friendly_display_format
    help_text.to_h_with_localizations(blank_placeholder: true)
  end

  def database_format
    help_text.to_h_with_localizations(blank_placeholder: false)
  end

  def identifiers_for_forms
    help_text.to_h_with_preset_keys
  end

  def revert_unless_presets_only
    HelpTextPresenter.new(help_text.revert_unless_presets_only, current_user)
  end

  private

  def service_provider_policy
    Pundit.policy(current_user, help_text.service_provider)
  end
end
