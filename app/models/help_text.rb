class HelpText
  include ActionView::Helpers::SanitizeHelper

  ALLOWED_HELP_TEXT_HTML_TAGS = %w[
    p
    br
    ol
    ul
    li
    a
    strong
    em
    b
  ].freeze

  def self.from_service_provider(sp)
    new(text: sp.help_text, service_provider: sp)
  end

  def self.options_enabled?
    IdentityConfig.store.help_text_options_feature_enabled
  end

  attr_reader :service_provider

  def initialize(text: {}, service_provider: nil)
    (@help_text, @service_provider) = [text, service_provider]
  end

  def options_enabled?
    HelpText.options_enabled?
  end

  def blank?
    @help_text.
      values.
      all? {|text| text.values.all?(&:blank?)}
  end

  # include translations of help text in DB
  def from_params(service_provider_params)
    current_help_text = service_provider_params.fetch('help_text')
    ServiceProviderHelper::SP_HELP_OPTS.each { |mode|
      key = current_help_text.fetch(mode).fetch('en').to_s
      no_value = key.empty?
      custom_help = !no_value &&
                    I18n.t("service_provider_form.help_text.#{mode}.#{key}", :default => '').empty?
      is_valid_key = ServiceProviderHelper::SP_HELP_KEYS[mode].include?(key)
      # check that one of the default options is selected and
      # don't overwrite custom help text
      if !no_value
        ServiceProviderHelper::SP_HELP_LOCALES.each { |locale|
          if key == 'blank' || custom_help || !is_valid_key
            # don't let people bypass the form
            chosen_text = ''
          else
            chosen_text = I18n.t("service_provider_form.help_text.#{mode}.#{key}",
              locale: locale,
              sp_name: service_provider.friendly_name,
              agency: service_provider.agency.name,
              )
          end

          current_help_text[mode][locale] = chosen_text
        }
      end
    }
    @help_text = current_help_text
    self # Allow chaining methods
  end

  def to_json
    @help_text
  end

  def sanitize_tags
    sections.each { |section| sanitize_section(section) }
    self
  end

  private

  def sections
    [@help_text['sign_in'], @help_text['sign_up'], @help_text['forgot_password']].compact
  end

  def sanitize_section(section)
    section.transform_values! do |translation|
      sanitize translation, tags: ALLOWED_HELP_TEXT_HTML_TAGS, attributes: %w[href target]
    end
  end

end
