process.env.NODE_ENV = process.env.NODE_ENV || 'development';

const environment = require('./environment');

environment.output.filename = "js/[name]-[hash].js";

module.exports = environment;
