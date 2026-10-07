const fs = require("fs");
const path = require("path");
const webpack = require("webpack");

const packsDir = 'app/javascript/packs';

const env = process.env.NODE_ENV || process.env.RAILS_ENV || 'development';
const isProductionEnv = env === 'production';

module.exports = {
  mode: isProductionEnv ? 'production' : 'development',
  devtool: isProductionEnv ? false : 'source-map',
  entry: fs.readdirSync(packsDir).filter((file) => file.endsWith('.js')).reduce((result, file) => {
    result[path.parse(file).name] = path.resolve(packsDir, file);
    return result;
  }, {}),
  output: {
    filename: "[name].js",
    sourceMapFilename: "[file].map",
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
