require 'rails_helper'

RSpec.describe '/security_events' do
  it 'routes all to #all' do
    expect(get: '/security_events/all').to route_to(
      controller: 'security_events',
      action: 'all',
    )
  end

  it 'routes search to #search' do
    expect(post: '/security_events/search').to route_to(
      controller: 'security_events',
      action: 'search',
    )
  end
end
