const path = require("path");
const webpack = require("webpack");

const env = process.env.NODE_ENV || process.env.RAILS_ENV || 'development';
const isProductionEnv = env === 'production';

module.exports = {
  mode: isProductionEnv ? 'production' : 'development',
  devtool: isProductionEnv ? false : 'eval-source-map',
  entry: {
    application: "./app/javascript/packs/application.js",
    manage_users: "./app/javascript/packs/manage_users.js",
    service_provider_form: "./app/javascript/packs/service_provider_form.js",
    validate_logo_size: "./app/javascript/packs/validate_logo_size.js",
  },
  output: {
    filename: `[name].js`,
    sourceMapFilename: `[name].js.map`,
    path: path.resolve(__dirname, `app/assets/builds`),
  },
  plugins: [
    new webpack.optimize.LimitChunkCountPlugin({
      maxChunks: 1
    })
  ],
  module: {
    rules: [
      {
        test: /\.(js)$/,
        exclude: /node_modules/,
        use: ['babel-loader'],
      },
    ],
  },
};
