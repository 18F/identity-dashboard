# `HelpTextPresenter` provides methods convienent for views and controlers about the display and
# perisistence of HelpText class properties.
#
# These methods would have been suitable for a helper module except Rails documentation is clear
# that helper modules should not persist state or use instance variables.
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

  # This generates a format suitable to displaying to partners in the portal.
  # Currently, this is the localized strings but blank text is replaced with the words "Leave blank"
  def friendly_display_format
    help_text.to_h_with_localizations(blank_placeholder: true)
  end

  # This generates the format we currently need in the IdP database.
  # These are the localized strings that are identitical to what users logging in to IdP will see.
  def database_format
    help_text.to_h_with_localizations(blank_placeholder: false)
  end

  # This generates shorthand placeholders whenever they're applicable, which is equivalent to saying
  # it uses the values in `HelpText::PRESETS` whenever possible
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
