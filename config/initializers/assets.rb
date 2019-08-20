# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = (Figaro.env.assets_version || '1.0')

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path
Rails.application.config.assets.paths << Rails.root.join('public',
                                                         'assets',
                                                         'identity-style-guide',
                                                         'dist',
                                                         'assets',
                                                         'img')
Rails.application.config.assets.paths << Rails.root.join('node_modules',
                                                         'identity-style-guide',
                                                         'dist',
                                                         'assets')
Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
Rails.application.config.assets.precompile += %w[ img/close.svg
                                                  img/favicons/favicon.ico
                                                  img/favicons/favicon.png
                                                  img/favicons/favicon-57.png
                                                  img/favicons/favicon-72.png
                                                  img/favicons/favicon-114.png
                                                  img/favicons/favicon-144.png
                                                  img/favicons/favicon-192.png
                                                  img/gsa-logo-rev.svg
                                                  img/icon-dot-gov.svg
                                                  img/icon-https.svg
                                                  img/illustrations/security-key.svg
                                                  img/login-gov-logo.svg
                                                  img/us_flag_small.png
                                                  js/main.js ]
