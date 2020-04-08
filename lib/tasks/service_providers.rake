namespace :service_providers do
  # rubocop:disable Rails/SkipsModelValidations
  task backfill_help_texts: [:environment] do |_task|
    ServiceProvider.find_each do |sp|
      sp.update_attribute(:help_text, sign_in: {}, sign_up: {}, forgot_password: {})
    end
  end
  # rubocop:enable Rails/SkipsModelValidations

  desc 'will clone identity-idp-config to access legacy logos and import into ActiveStorage'
  task import_legacy_logos: [:environment] do |_task|
    logo_updater = ServiceProviderLogoUpdater.new
    logo_updater.import_logos_to_active_storage
  end
end
