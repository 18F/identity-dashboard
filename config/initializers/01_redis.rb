# frozen_string_literal: true

# This file is named 01_redis.rb so that it is loaded before rack_attack.rb.
# This is done because rack_attack.rb needs to reference the Throttle pool defined here.
REDIS_THROTTLE_POOL = ConnectionPool.new(size: IdentityConfig.store.redis_throttle_pool_size) do
  Redis.new(url: IdentityConfig.store.redis_throttle_url)
end.freeze
