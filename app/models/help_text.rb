
# If we do more work on this, it should be its own model instead of a column in Service Providers
# This current iteration is an attempt to add some functionality without a the sizable refactor
# required to create that new model
class HelpText
  CONTEXTS = ['sign_in', 'sign_up', 'forgot_password'].freeze
  LOCALES = ['en', 'es', 'fr', 'zh'].freeze

  # Hash<String,Array<String>> PRESETS A collection of valid preset help texts
  # Hash keys are valid CONTEXTS values. Arrays are a list of keys in the locale YAML files
  PRESETS = {
    'sign_in' => ['blank', 'first_time', 'agency_email', 'piv_cac'],
    'sign_up' => ['blank', 'first_time', 'agency_email', 'same_email'],
    'forgot_password' => ['blank', 'troubleshoot_html'],
  }.freeze

  # include translations of help text in DB
  def self.lookup(params: nil, service_provider: nil)
    raise ArgumentError, '`HelpText.lookup`: nothing to look up' unless params || service_provider
    params ||= service_provider.attributes['help_text'] unless service_provider&.attributes.blank?

    new(help_text: params, service_provider: service_provider)
  end

  attr_reader :help_text, :service_provider

  def initialize(help_text: {}, service_provider: nil)
    @help_text = help_text
    @service_provider = service_provider || ServiceProvider.new
  end

  def blank?
    CONTEXTS.any? do |context|
      next unless help_text[context]
      blank_preset_allowed = PRESETS[context].include? 'blank'
      help_text[context].values.any? do |value|
        return false if !(value.blank? || blank_preset_allowed && value == 'blank')
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
    HelpText.lookup(service_provider: service_provider)
  end

  def to_h
    result = {}
    CONTEXTS.each do |context|
      result[context] = Hash.new
      value = help_text.fetch(context, nil)&.fetch('en', nil)
      is_a_preset = PRESETS[context].include?(value)
      LOCALES.each do |locale|
        if is_a_preset
          result[context][locale] = value == 'blank' ? '' : I18n.t(
            "service_provider_form.help_text.#{context}.#{value}",
            locale: locale,
            sp_name: service_provider.friendly_name,
            agency: service_provider.agency&.name,
          )
        elsif value && help_text[context].fetch(locale, false)
          result[context][locale] = help_text[context][locale]
        end
      end
    end
    result
  end
end
