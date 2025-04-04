require 'rails_helper'

describe HelpText do
  let(:service_provider) { build(:service_provider) }
  let(:subject) { HelpText.lookup(service_provider:) }
  let(:all_presets_help_text) do
    HelpText::CONTEXTS.each_with_object(Hash.new) do |context, result|
      result[context] = Hash.new
      HelpText::LOCALES.each do |locale|
        result[context][locale] = HelpText::PRESETS[context].sample
      end
    end
  end
  let(:maybe_presets_help_text) do
    HelpText::CONTEXTS.each_with_object(Hash.new) do |context, result|
      result[context] = Hash.new
      preset = rand(2) == 1 ? HelpText::PRESETS[context].sample : nil
      HelpText::LOCALES.each do |locale|
        result[context][locale] = if preset
          I18n.t(
            "service_provider_form.help_text.#{context}.#{preset}",
            locale: locale,
            sp_name: service_provider.friendly_name,
            agency: service_provider.agency&.name,
          )
        else
          ['Pruebas con <em>HTML</em>', 'This is a test!'].sample
        end
      end
    end
  end
  let(:blank_help_text) do
    HelpText::CONTEXTS.each_with_object(Hash.new) do |context, result|
      result[context] = Hash.new
      can_be_blank = HelpText::PRESETS[context].include?('blank')
      options = ['', ' ', '     ']
      options += ['blank'] if can_be_blank
      HelpText::LOCALES.each do |locale|
        result[context][locale] = options.sample
      end
    end
  end

  RSpec::Matchers.matcher :be_a_help_text_preset_for do |context|
    match do |actual|
      HelpText::PRESETS[context].include?(actual)
    end
  end

  describe '.lookup' do
    it 'does not modify the help text by default' do
      expect(subject.help_text.to_json).to eq(service_provider.help_text.to_json)
    end

    it 'does not modify more complicated help text' do
      service_provider.help_text = maybe_presets_help_text
      expect(subject.help_text.to_json).to eq(service_provider.help_text.to_json)
    end

    it 'keeps presets as presets' do
      subject = HelpText.lookup(params: all_presets_help_text, service_provider: service_provider)
      HelpText::CONTEXTS.each do |context|
        HelpText::LOCALES.each do |locale|
          expect(subject.fetch(context, locale)).to be_a_help_text_preset_for(context)
        end
      end
    end
  end

  describe '#blank?' do
    it 'is true for blank text' do
      help_text_from_params = HelpText.lookup(
        service_provider: service_provider,
        params: { 'help_text' => blank_help_text },
      )
      expect(help_text_from_params).to be_blank

      service_provider.help_text = blank_help_text
      expect(subject).to be_blank
    end

    it 'is true for an empty hash' do
      help_text_from_params = HelpText.lookup(
        service_provider: service_provider,
        params: { 'help_text' => {} },
      )
      expect(help_text_from_params).to be_blank
      service_provider.help_text = {}
      expect(subject).to be_blank
    end

    it 'is true for a new ServiceProvider' do
      new_service_provider = ServiceProvider.new
      expect(HelpText.lookup(service_provider: new_service_provider)).to be_blank
    end

    it 'is false for a more complicated example' do
      # Prevent a flaky test: make sure we didn't accidentally RNG into all `'blank'` presets
      all_presets_help_text[HelpText::CONTEXTS.first][HelpText::LOCALES.sample] = 'first_time'
      service_provider.help_text = all_presets_help_text
      expect(subject).to_not be_blank
    end
  end

  describe '#presets_only?' do
    it 'is true when everything is a preset key' do
      service_provider.help_text = all_presets_help_text
      expect(subject).to be_presets_only
    end

    it 'is false when one value is not a preset key' do
      one_value_off_help_text = all_presets_help_text.dup
      one_value_off_help_text[HelpText::CONTEXTS.sample][HelpText::LOCALES.sample] =
        'This is definitely not one of our presets'
      service_provider.help_text = one_value_off_help_text
      expect(subject).to_not be_presets_only
    end

    it 'is true when some values are the full text of the preset values' do
      HelpText::CONTEXTS.each do |context|
        HelpText::LOCALES.each do |locale|
          value = all_presets_help_text[context][locale]
          all_presets_help_text[context][locale] = I18n.t(
            "service_provider_form.help_text.#{context}.#{value}",
            locale: locale,
            sp_name: service_provider.friendly_name,
            agency: service_provider.agency.name,
          )
        end
      end
      service_provider.help_text = all_presets_help_text
      expect(subject).to be_presets_only
    end
  end

  describe '#to_localized_h' do
    it 'keeps everything the same with simple options' do
      expect(subject.help_text.to_json).to eq(service_provider.help_text.to_json)
    end

    it 'writes out localized presets' do
      service_provider = build(:service_provider, agency: build(:agency))
      # 'sign_in' and 'sign_up' both have a service provider name substitution and
      # an agency name substitution in their localizations.
      # We can use them to test both format substitution options
      all_presets_help_text['sign_in']['en'] = 'first_time'
      all_presets_help_text['sign_up']['en'] = 'agency_email'
      results = HelpText.lookup(
        params: all_presets_help_text,
        service_provider: service_provider,
      ).to_localized_h
      random_locale = HelpText::LOCALES.sample
      sign_in_first_time_text = I18n.t(
        'service_provider_form.help_text.sign_in.first_time',
        locale: random_locale,
        sp_name: service_provider.friendly_name,
        agency: service_provider.agency.name,
      )
      sign_up_agnecy_text = I18n.t(
        'service_provider_form.help_text.sign_up.agency_email',
        locale: random_locale,
        sp_name: service_provider.friendly_name,
        agency: service_provider.agency.name,
      )

      expect(subject.help_text.to_json).to_not eq(service_provider.help_text.to_json)
      expect(results['sign_in'][random_locale]).to eq(sign_in_first_time_text)
      expect(results['sign_up'][random_locale]).to eq(sign_up_agnecy_text)
    end
  end

  it 'writes out localized presets even if the presets were not evenly edited' do
    test_context = HelpText::CONTEXTS.sample
    all_but_one_preset = all_presets_help_text.dup
    all_but_one_preset[test_context]['en'] = 'I accidentally only updated English'
    expect(all_but_one_preset[test_context]['es']).to be_a_help_text_preset_for(test_context)
    subject = HelpText.lookup(params: all_but_one_preset, service_provider: service_provider)
    localized_vaules_for_context = subject.to_localized_h[test_context]
    HelpText::LOCALES.each do |locale|
      expect(localized_vaules_for_context[locale]).to_not be_a_help_text_preset_for(test_context)
    end
  end

  describe '#revert_unless_presets_only' do
    let(:service_provider) { ServiceProvider.new(help_text: maybe_presets_help_text) }

    context 'when params are all presets' do
      let(:params) { all_presets_help_text }

      it 'uses the params over the service provider' do
        subject = HelpText.lookup(params:, service_provider:)
        subject = subject.revert_unless_presets_only
        expect(subject.help_text.to_json).to eq(params.to_json)
        expect(subject.help_text.to_json).to_not eq(service_provider.help_text.to_json)
      end
    end
    context 'when the params are not all presets do' do
      let(:params) do
        params = all_presets_help_text
        # Be absolutely sure at least one param is not a preset
        params[HelpText::CONTEXTS.sample][HelpText::LOCALES.sample] = [
          'Pruebas con <em>HTML</em>',
          'This is a test!',
        ].sample
        params
      end

      it 'reverts to the service provider and throws away the params' do
        subject = HelpText.lookup(params:, service_provider:)
        subject = subject.revert_unless_presets_only
        expect(subject.help_text.to_json).to_not eq(params.to_json)
        expect(subject.help_text.to_json).to eq(service_provider.help_text.to_json)
      end
    end
  end
end
