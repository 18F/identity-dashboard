# If we do more work on this, it should be its own model instead of a column in Service Providers
# This current iteration is an attempt to add some functionality without a the sizable refactor
# required to create that new model
class HelpText
  UI_CONTEXTS = %w[sign_in sign_up forgot_password].freeze
  LOCALES = %w[en es fr zh].freeze
  # If a preset is set for one locale, it should be the same for all of them.
  # On the off chance that something is unexpected in the database, pick one to be authoritative
  LOCALE_FOR_PRESETS = 'en'.freeze

  # Hash<String,Array<String>> PRESETS A collection of valid preset help texts
  # Hash keys are valid UI_CONTEXTS values. Arrays are a list of keys in the locale YAML files
  PRESETS = {
    'sign_in' => %w[blank first_time agency_email piv_cac],
    'sign_up' => %w[blank first_time agency_email same_email],
    'forgot_password' => ['blank', 'troubleshoot_html'],
  }.freeze

  # A HelpTextEntry represents one item in the nested collections of UI contexts and locales
  class HelpTextEntry
    attr_reader :preset, :text

    def make_blank
      @preset = true
      @text = 'blank'
      self
    end

    def make_preset(preset)
      @preset = true
      @text = preset
      self
    end

    def make_text(text)
      @preset = false
      @text = text
      self
    end

    def preset?
      @preset
    end

    def blank?
      preset? && @text == 'blank'
    end
  end

  # HelpText.lookup returns a HelpText instance that represents all the chosen help text
  #
  # If you provide `params` as well as `service_provider`, the vaules in `params` will be used with
  # the `service_provider` only relevant for filling in friendly names in the help text or when
  # using `#revert_unless_presets_only`.
  #
  # A service provider is required because, without a service provider reference,
  # the localizations won't have enough context.
  def self.lookup(service_provider:, params: nil)
    raise ArgumentError, '`HelpText.lookup`: nothing to look up' unless params || service_provider

    params ||= service_provider.attributes['help_text'] if service_provider&.attributes.present?

    new(help_text: params, service_provider: service_provider)
  end

  attr_reader :service_provider

  def initialize(help_text: {}, service_provider: nil)
    @initial_help_text = help_text
    @service_provider = service_provider || ServiceProvider.new
    @persisted_help_text = @service_provider.help_text.dup
    strings_to_help_text_entries
  end

  def blank?
    @help_text_entries.values.all? do |each_context|
      each_context.values.all?(&:blank?)
    end
  end

  def presets_only?
    @help_text_entries.values.all? do |each_ui_context|
      each_ui_context.values.all?(&:preset?)
    end
  end

  def revert_unless_presets_only
    return self if presets_only?

    HelpText.lookup(params: @persisted_help_text, service_provider: service_provider)
  end

  # This takes the nested hashes of HelpTextEntries and turns them into
  # hashes of strings. If the entries are presets, the outputted strings
  # will use the preset shorthand strings in the PRESETS constant
  def to_h_with_preset_keys
    index_each_possible_entry do |ui_context, locale|
      entry = @help_text_entries[ui_context][locale]
      next 'blank' if entry.blank?

      entry.text
    end
  end

  # This takes the nested hashes of HelpTextEntries and turns them into
  # hashes of strings. If the entries are presets, the outputted strings
  # will be pulled from the locale files.
  #
  # @param blank_placeholder [Boolean] If true, use the words from the locale files for blank
  #   entries (currently "Leave blank"). If false, use the empty string. Default: false
  def to_h_with_localizations(blank_placeholder: false)
    index_each_possible_entry do |ui_context, locale|
      entry = @help_text_entries[ui_context][locale]
      next '' if entry.blank? && !blank_placeholder

      if entry.preset?
        I18n.t(
          "service_provider_form.help_text.#{ui_context}.#{entry.text}",
          locale: locale,
          sp_name: sp_name,
          agency: agency_name,
        )
      else
        entry.text
      end
    end
  end

  def to_json(*)
    to_h_with_localizations.to_json(*)
  end

  private

  # Usage example:
  #
  # index_each_possible_entry do |context, locale|
  #   "this is #{locale} for context #{context}"
  # end
  #
  # will return a hash that looks like
  # { 'sign_in' => {
  #     'en' => 'this is en for sign_in',
  #     'es' => 'this is es for sign_in',
  #     # ...etc...
  #   },
  #   'sign_up' => {
  #     'en' => 'this is en for sign_up',
  #     'es' => 'this is es for sign_up'
  #     # ...etc...
  #   },
  # }
  def index_each_possible_entry
    UI_CONTEXTS.index_with do |ui_context|
      LOCALES.index_with do |locale|
        yield ui_context, locale
      end
    end
  end

  def strings_to_help_text_entries
    @help_text_entries = index_each_possible_entry do |ui_context, locale|
      this_locale_starting_text = @initial_help_text.dig(ui_context, locale)
      this_locale_starting_text ||= @initial_help_text.dig(ui_context, LOCALE_FOR_PRESETS)

      entry = HelpText::HelpTextEntry.new
      next entry.make_blank unless this_locale_starting_text.present?

      preset = matching_preset(ui_context, locale, this_locale_starting_text)
      next entry.make_preset(preset) if preset

      entry.make_text(@initial_help_text[ui_context][locale])
    end
  end

  def matching_preset(ui_context, locale, text)
    return text if PRESETS[ui_context].include? text

    PRESETS[ui_context].each do |preset|
      return preset if text == I18n.t(
        "service_provider_form.help_text.#{ui_context}.#{preset}",
        locale: locale,
        sp_name: sp_name,
        agency: agency_name,
      )
    end

    false
  end

  def sp_name
    service_provider.friendly_name
  end

  def agency_name
    service_provider.agency&.name
  end
end
