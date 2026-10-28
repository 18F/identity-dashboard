# Takes a list of error description strings returned form Zendesk.
# It helps arrange the messages so we can communicate whether these are errors a partner user could
# or couldn't do something about.
class ZendeskErrors
  attr_reader :errors

  # I'm certain other errors are unrecoverable.
  # These errors are most common in dev environments. We can add others later as needed.
  UNRECOVERABLE_ERROR_MESSAGES = [
    'Portal Configuration URL',
    'Rate limit exceeded',
  ].freeze

  def initialize(api_errors)
    @errors = api_errors
  end

  # @return Boolean
  def any?
    errors.present? && parsed_errors.any?
  end

  # @return Array
  def unrecoverable_errors
    return [] unless any?

    @unrecoverable_errors ||= parsed_errors.filter do |e|
      UNRECOVERABLE_ERROR_MESSAGES.any? do |message|
        e.include?(message)
      end
    end
  end

  # @return Array
  def user_facing_errors
    return [] unless any?
    return [] if unrecoverable_errors.any?

    parsed_errors
  end

  # I think for now we should show the unrecoverable errors to the partner so they can send us a
  # screenshot to help troubleshoot any problems.
  # Maybe later we could log these instead.
  #
  # @return Array
  def messages
    return user_facing_errors unless unrecoverable_errors.any?

    unrecoverable_errors
  end

  # @return String
  def initial_text
    if unrecoverable_errors.any?
      return 'We are unable to submit requests through this form right now.'
    end

    return 'An unknown error occurred.' unless any?

    'Please fix the following problems with your configuration before submitting a request.'
  end

  # @return String
  def remaining_text
    # Zendesk error messages do not end with a period, so we can join them with one
    [*messages, final_message].join('. ')
  end

  # This is a closing message with instructions on what the user can do next.
  # This text does end with a period under the assumption that there's no further messages to `join`
  #
  # @return String
  def final_message
    return 'Please try again.' if any? && unrecoverable_errors.none?

    'You can create a request manually through ' \
      '<a href="https://partners.login.gov/hc/en-us/requests/new">this contact form</a> instead.'
  end

  private

  def parsed_errors
    errors.filter_map { |e| e['description'] }
  end
end
