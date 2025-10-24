# All ServiceProviders with the disabling status, `moved_to_prod`
# @return [Array<ServiceProvider>]
def all_disabled_configs
  ServiceProvider.where(issuer: SAMPLE_ISSUERS).filter do |sp|
    sp.status == 'moved_to_prod'
  end
end
