const { environment } = require('@rails/webpacker')
const { NormalModuleReplacementPlugin } = require('webpack');
const path = require('path');
const fs = require('fs');

const stub = path.join(process.cwd(), 'app/javascript/v2/stub.js');

environment.plugins.set(
    'StubComponents',
    new NormalModuleReplacementPlugin(/^\..?\/[A-Z]/, function(resource) {
        const { context, request, contextInfo: { issuer }} = resource;
        if (!/app\/javascript\/v2\/components/.test(context)) return;
        if (fs.existsSync(path.join(context, `${request}.js`))) return;
        if (fs.existsSync(path.join(context, `${request}.jsx`))) return;

        console.warn(`\nStubbing ${request} from ${issuer}\n`);
        resource.request = stub;
    })
)

module.exports = environment
