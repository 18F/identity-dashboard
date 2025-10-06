class ServiceProviderUpdaterPolicy < BasePolicy # :nodoc:
  def publish?
    !!user && !IdentityConfig.store.prod_like_env
  end
end
