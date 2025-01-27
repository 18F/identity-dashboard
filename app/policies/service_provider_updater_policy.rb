class ServiceProviderUpdaterPolicy < BasePolicy
  def publish?
    !!user
  end
end
