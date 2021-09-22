process.env.NODE_ENV = process.env.NODE_ENV || 'production'

const webpackConfig = require('./base')

delete webpackConfig.entry.component_demos

module.exports = webpackConfig
