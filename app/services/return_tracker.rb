# Return tracker stores state (using `ReturnTracker#set`) between page loads so we can return to
# a desired path later based on the stored value.
#
# Since we have more than one return link we want to save state for, specify which link you're
# reading or writing the state of with the `tracking_key` argument passed to the initializer.
#
# We expect a controller will supply the key-value store used to persist state.
#
# Because the store itself may be user-controlled cookie store, we must treat it like any user input
# and assure it only gives us values we consider safe. Safe values are in `TRACKING_KEY_VALUES`
#
# `TRACKING_KEY_VALUES` also can, if needed include link text if displying the return path as a link
class ReturnTracker
  include Rails.application.routes.url_helpers

  attr_reader :store, :tracking_key, :stored_id

  TRACKING_KEY_VALUES = {
    team: {
      'all' => { path: :teams_all_path },
      default: { path: :teams_path },
    },
    config: {
      'team_index' => { path: :teams_path, text: 'View teams' },
      'config_index' => { path: :service_providers_path, text: 'View configurations' },
      'team' => { path: :team_path, needs_id: true, text: 'Return to team %{name}' },
      default: { path: :service_providers_path, text: 'View configurations' },
    },
  }.freeze

  def initialize(store, tracking_key)
    @store, @tracking_key = store, tracking_key
    @stored_id = nil
  end

  def set(value)
    store["return_#{tracking_key}"] = value
  end

  def path
    public_send TRACKING_KEY_VALUES[tracking_key][stored_value][:path], @stored_id
  end

  def text
    TRACKING_KEY_VALUES[tracking_key][stored_value][:text]
  end

  private

  def stored_value
    # Since the store currently defaults to the cookie store, it's possible for a user to
    # arbitrarily pick a value. We need to sanitize all user input.
    value = store["return_#{tracking_key}"]

    return :default unless value.present?
    return value if TRACKING_KEY_VALUES[tracking_key].include? value

    pair = value.split ','
    if pair.count == 2 && valid_pair(*pair)
      @stored_id = pair.second
      return pair.first
    end

    :default
  end

  # Reject the pair if the path need no ID or if the ID has any non-numeric characters
  def valid_pair(key, id)
    TRACKING_KEY_VALUES[tracking_key].fetch(key, {})[:needs_id] && id.tr('0-9', '').empty?
  end
end
