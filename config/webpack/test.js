process.env.NODE_ENV = process.env.NODE_ENV || 'development'

const webpackConfig = require('./base')

delete webpackConfig.entry.component_demos

module.exports = webpackConfig;
