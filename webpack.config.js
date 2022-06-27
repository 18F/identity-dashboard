const path = require("path");
const { sync: glob } = require('fast-glob');
const webpack = require("webpack");

const env = process.env.NODE_ENV || process.env.RAILS_ENV || 'development';
const isProductionEnv = env === 'production';

module.exports = {
  mode: isProductionEnv ? 'production' : 'development',
  devtool: isProductionEnv ? false : 'eval-source-map',
  entry: glob('app/javascript/packs/*.js').reduce((result, filepath) => {
    result[path.parse(filepath).name] = path.resolve(filepath);
    return result;
  }, {}),
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
