// Run `bin/rake tailwind:compile` if you change this file
const defaultTheme = require('./app/javascript/v2/node_modules/tailwindcss/defaultTheme');

module.exports = {
  purge: [
    './app/javascript/v2/components/**/*.{js,jsx}',
    './app/views/**/*.{js,erb,haml}'
  ],
  darkMode: false, // or 'media' or 'class'
  theme: {
    extend: {
      colors: {
        github: {
          green: '#6cc644',
          red: '#bd2c00',
          purple: '#6e5494'
        }
      },
      fontFamily: {
        sans: ['Lato', ...defaultTheme.fontFamily.sans]
      }
    }
  },
  variants: {
    extend: {},
  },
  plugins: [],
}
