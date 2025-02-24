
# If we do more work on this, it should be its own model instead of a column in Service Providers
# This current iteration is an attempt to add some functionality without a the sizable refactor
# required to create that new model
class HelpText
  CONTEXTS = %w[sign_in sign_up forgot_password].freeze
  LOCALES = %w[en es fr zh].freeze
  # If a preset is set for one locale, it should be the same for all of them.
  # On the off chance that something is unexpected in the database, pick one to be authoritative
  LOCALE_FOR_PRESETS = 'en'.freeze

  # Hash<String,Array<String>> PRESETS A collection of valid preset help texts
  # Hash keys are valid CONTEXTS values. Arrays are a list of keys in the locale YAML files
  PRESETS = {
    'sign_in' => %w[blank first_time agency_email piv_cac],
    'sign_up' => %w[blank first_time agency_email same_email],
    'forgot_password' => ['blank', 'troubleshoot_html'],
  }.freeze

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

    params ||= service_provider.attributes['help_text'] unless service_provider&.attributes.blank?

    new(help_text: params, service_provider: service_provider)
  end

  attr_reader :help_text, :service_provider

  def initialize(help_text: {}, service_provider: nil)
    @help_text = help_text
    @service_provider = service_provider || ServiceProvider.new
    @initial_help_text = @service_provider.help_text.dup
    revert_presets_to_short_name
  end

  def blank?
    CONTEXTS.any? do |context|
      next unless help_text[context]

      help_text[context].values.any? do |value|
        return false unless blank_text?(value)
      end
    end
    true
  end

  def presets_only?
    CONTEXTS.each do |context|
      next unless help_text[context]

      LOCALES.each do |locale|
        next if help_text[context][locale].blank?
        return false unless PRESETS[context].include?(
          help_text[context][locale],
        )
      end
    end
    true
  end

  def revert_unless_presets_only
    return self if presets_only?

    HelpText.lookup(params: @initial_help_text, service_provider: service_provider)
  end

  def fetch(context, lang)
    help_text.fetch(context, {})[lang]
  end

  def to_localized_h
    is_presets_only = presets_only?
    result = {}
    CONTEXTS.each do |context|
      result[context] = Hash.new
      base_value = fetch(context, LOCALE_FOR_PRESETS)
      LOCALES.each do |locale|
        value = is_presets_only ? base_value : fetch(context, locale)
        is_a_preset = PRESETS[context].include?(value)
        if is_a_preset
          result[context][locale] = blank_text?(value) ? '' : I18n.t(
            "service_provider_form.help_text.#{context}.#{value}",
            locale: locale,
            sp_name: sp_name,
            agency: agency_name,
          )
        elsif base_value && fetch(context, locale)
          result[context][locale] = help_text[context][locale]
        end
      end
    end
    result
  end

  private

  def sp_name
    service_provider.friendly_name
  end

  def agency_name
    service_provider.agency&.name
  end

  def revert_presets_to_short_name
    CONTEXTS.each do |context|
      next if help_text[context].blank?

      PRESETS[context].each do |preset|
        LOCALES.each do |locale|
          help_text[context][locale] = 'blank' and next if blank_text?(help_text[context][locale])

          if help_text[context][locale] == I18n.t(
            "service_provider_form.help_text.#{context}.#{preset}",
            locale: locale,
            sp_name: sp_name,
            agency: agency_name,
          )
            help_text[context][locale] = preset
          end
        end
      end
    end
  end

  def blank_text?(text)
    text.blank? || text == 'blank' || text == 'Leave blank'
  end
end
