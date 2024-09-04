# rubocop:disable Metrics/BlockLength
SimpleForm.browser_validations = false
SimpleForm.setup do |config|
  config.button_class = 'btn btn-primary'
  config.boolean_label_class = nil
  config.error_notification_tag = :div
  config.error_notification_class =
    'usa-alert usa-alert--error usa-alert__body usa-alert__text text-indent-3'

  config.wrappers :base do |b|
    b.use :html5
    # change input class from field to usa-input
    b.use :input, class: 'usa-input'
    b.use :hint,  wrap_with: { tag: :span, class: 'usa-hint' }
  end

  config.wrappers :vertical_form, tag: 'div', class: 'wizard-field', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.wrapper tag: :div, class: 'usa-label__group' do |c|
      c.wrapper tag: :label, class: 'usa-label' html: { role: 'alert' } do |d|
        d.use :label, class: 'usa-label'
        d.use :error, wrap_with: { tag: 'p', class: 'usa-sr-only' }
      end
      c.use :hint,  wrap_with: { tag: 'p', class: 'usa-hint' }
    end
    b.wrapper tag: :div, class: 'usa-input__container' do |c|
      c.use :input, class: 'block col-12' # usa-input'
      c.use :error, wrap_with: { tag: 'p', class: 'usa-error-message' }
    end
  end

  config.default_wrapper = :vertical_form
  config.label_text = lambda do |label, required, _explicit_label|
    # rubocop:disable Rails/OutputSafety
    label + required.html_safe
    # rubocop:enable Rails/OutputSafety
  end
end
# rubocop:enable Metrics/BlockLength
