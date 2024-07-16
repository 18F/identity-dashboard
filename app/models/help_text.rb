
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

    result = new(help_text: params, service_provider: service_provider)
    result.send(:revert_presets_to_short_name)
    result
  end

  attr_reader :help_text, :service_provider

  def initialize(help_text: {}, service_provider: nil)
    @help_text = help_text
    @service_provider = service_provider || ServiceProvider.new
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
    HelpText.lookup(service_provider: service_provider)
  end

  def fetch(context, lang = 'en')
    help_text.fetch(context, {})[lang]
  end

  def to_h
    result = {}
    CONTEXTS.each do |context|
      result[context] = Hash.new
      english_setting = fetch(context)
      is_a_preset = PRESETS[context].include?(english_setting)
      LOCALES.each do |locale|
        if is_a_preset
          result[context][locale] = blank_text?(english_setting) ? '' : I18n.t(
            "service_provider_form.help_text.#{context}.#{english_setting}",
            locale: locale,
            sp_name: sp_name,
            agency: agency_name,
          )
        elsif english_setting && fetch(context, locale)
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
