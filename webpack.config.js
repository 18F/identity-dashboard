const path = require("path");
const { sync: glob } = require("fast-glob");
const webpack = require("webpack");

const env = process.env.NODE_ENV || process.env.RAILS_ENV || "development";
const isProductionEnv = env === "production";

module.exports = {
  mode: isProductionEnv ? "production" : "development",
  devtool: isProductionEnv ? false : "source-map",
  resolve: {
    extensions: [".js", ".jsx", ".ts", ".tsx"],
  },
  entry: glob("app/javascript/packs/*.{js,ts,tsx,jsx}").reduce(
    (result, filepath) => {
      result[path.parse(filepath).name] = path.resolve(filepath);
      return result;
    },
    {}
  ),
  output: {
    // module: true
    filename: "[name].js",
    sourceMapFilename: "[file].map",
    path: path.resolve(__dirname, `app/assets/builds`),
    module: true, // Ensures the output is an ES module
  },
  module: {
    rules: [
      {
        test: /\.[jt]sx?$/,
        exclude: /node_modules/,
        use: {
          loader: "babel-loader",
          options: {
            presets: [
              "@babel/preset-env",
              [
                "@babel/preset-typescript",
                { isTSX: true, allExtensions: true },
              ],
              [
                "@babel/preset-react",
                { runtime: "automatic", importSource: "preact" },
              ],
            ],
          },
        },
      },
      {
        test: /\.svg$/i,
        type: "asset/resource", // Emits the SVG file as a separate asset
        generator: {
          filename: "images/[name].[hash][ext]", // Output path for SVGs
        },
      },
    ],
  },
  experiments: {
    outputModule: true, // Enables module output
  },
  plugins: [new webpack.optimize.LimitChunkCountPlugin({ maxChunks: 1 })],
};
