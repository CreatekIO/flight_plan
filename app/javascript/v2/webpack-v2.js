// MONKEYPATCHES
const helpers = require('@rails/webpacker/package/utils/helpers');

const originalModuleExists = helpers.moduleExists;
const originalCanProcess = helpers.canProcess;

const IGNORED = ['sass-loader']

helpers.moduleExists = (name) =>
    IGNORED.includes(name) ? null : originalModuleExists(name);

helpers.canProcess = (name, fn) =>
    IGNORED.includes(name) ? null : originalCanProcess(name, fn);
// END MONKEYPATCHES

const { webpackConfig, merge } = require('@rails/webpacker');
const { NormalModuleReplacementPlugin } = require('webpack');
const path = require('path');
const fs = require('fs');

const stub = path.join(process.cwd(), 'stub.js');

const customConfig = {
    resolve: { extensions: ['.jsx'] },
    plugins: [
        new NormalModuleReplacementPlugin(/^\..?\/[A-Z]/, function(resource) {
            const { context, request, contextInfo: { issuer }} = resource;
            if (!/app\/javascript\/v2\/components/.test(context)) return;
            if (fs.existsSync(path.join(context, `${request}.js`))) return;
            if (fs.existsSync(path.join(context, `${request}.jsx`))) return;

            console.warn(`Stubbing ${request} from ${issuer}`);
            resource.request = stub;
        })
    ]
};

module.exports = merge(webpackConfig, customConfig);
