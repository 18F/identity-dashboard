# Permission policy for writing ServiceProvider updates to staging IdP DB
class ServiceProviderUpdaterPolicy < BasePolicy
  def publish?
    !!user && !IdentityConfig.store.prod_like_env
  end
end
