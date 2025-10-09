# Permission policy for the ServiceProviderUpdater
class ServiceProviderUpdaterPolicy < BasePolicy
  def publish?
    !!user && !IdentityConfig.store.prod_like_env
  end
end
