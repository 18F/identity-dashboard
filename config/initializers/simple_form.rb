SimpleForm.setup do |config|
  # Karla Rodriguez changed style from 'btn btn-primary'
  
  config.button_class = 'btn btn-primary'
  config.boolean_label_class = nil
  config.error_notification_tag = :div
  config.error_notification_class = 'error-notify red bold mb2'

  config.wrappers :base do |b|
    b.use :html5
    b.use :hint,  wrap_with: { tag: :span, class: :hint }
    # change input class from field to usa-input
    b.use :input, class: 'usa-input'
    
  end

  config.wrappers :usa_radio, :tag => 'fieldset', :class => 'usa-fieldset', :error_class => 'error' do |b|
    b.use :html5
    b.use :placeholder
    b.use :label
    b.wrapper :tag => 'ul', :class => 'usa-input-list' do |input|
      input.use :input, :wrap_with => { :tag => 'li', :class => 'block-wrapper' }
      input.use :error, :wrap_with => { :tag => 'span', :class => 'help-inline' }
      input.use :hint,  :wrap_with => { :tag => 'p', :class => 'help-block' }
    end
   end
  config.wrappers :usa_checkbox, :tag => 'fieldset', :class => 'usa-fieldset', :error_class => 'error' do |b|
    b.use :html5
    b.use :placeholder
    b.use :label
    b.wrapper :tag => 'ul', :class => 'usa-input-list' do |input|
      input.use :input, :wrap_with => { :tag => 'li', :class => 'usa-checkbox__input' }
      input.use :error, :wrap_with => { :tag => 'span', :class => 'help-inline' }
      input.use :hint,  :wrap_with => { :tag => 'p', :class => 'help-block' }
    end
  end 
  config.wrappers :vertical_form, tag: 'div', class: 'mb2', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: 'usa-label'
    # changed input class from field to usa-input
    b.use :input, class: 'block col-12' # usa-input'
    b.use :hint,  wrap_with: { tag: 'div', class: 'usa-form-hint' }
    b.use :error, wrap_with: { tag: 'div', class: 'error-notify alert-danger p1 mt1' }
  end

  config.default_wrapper = :vertical_form
end


