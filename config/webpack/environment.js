const { environment } = require('@rails/webpacker');
const merge = require('webpack-merge');
const webpack = require('webpack');

module.exports = environment;

environment.plugins.prepend(
  'Provide',
  new webpack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery',
    jquery: 'jquery'
  })
);

const envConfig = environment;
const aliasConfig = {
  resolve: {
    alias: {
      jquery: 'jquery/src/jquery'
    }
  }
};

module.exports = merge(envConfig.toWebpackConfig(), aliasConfig);
