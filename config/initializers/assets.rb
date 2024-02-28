# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
Rails.application.config.assets.paths.push(
  'node_modules/identity-style-guide/dist/assets/img',
  'node_modules/identity-style-guide/dist/assets/fonts',
  'node_modules/identity-style-guide/dist/assets/js',
)
