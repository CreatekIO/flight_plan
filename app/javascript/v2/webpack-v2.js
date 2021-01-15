// MONKEYPATCHES
const helpers = require('@rails/webpacker/package/utils/helpers');

const originalModuleExists = helpers.moduleExists;
const originalCanProcess = helpers.canProcess;

const IGNORED = ['css-loader', 'sass-loader']

helpers.moduleExists = (name) =>
    IGNORED.includes(name) ? null : originalModuleExists(name);

helpers.canProcess = (name, fn) =>
    IGNORED.includes(name) ? null : originalCanProcess(name, fn);
// END MONKEYPATCHES

const { webpackConfig, merge } = require('@rails/webpacker');

const customConfig = {
    resolve: { extensions: ['.jsx'] }
};

module.exports = merge(webpackConfig, customConfig);
