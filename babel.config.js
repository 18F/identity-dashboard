module.exports = (api) => {
  const isTestEnv = api.env('test');

  let targets;
  if (isTestEnv) {
    targets = 'current node';
  } else {
    targets = 'defaults'
  }

  return {
    presets: [
      ['@babel/preset-env', { targets }],
    ],
  }
};
