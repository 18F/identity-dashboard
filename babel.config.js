module.exports = (api) => {
  const isTestEnv = api.env('test');

  let targets;
  if (isTestEnv) {
    targets = 'current node';
  } else {
    targets = '> 1% or IE 11';
  }

  return {
    presets: [
      ['@babel/preset-env', { targets }],
    ],
    plugins: [
      ['polyfill-corejs3', { method: 'usage-global', targets }],
      ['polyfill-regenerator', { method: 'usage-global', targets }],
    ],
  };
};
