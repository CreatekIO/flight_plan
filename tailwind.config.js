const defaultTheme = require('./app/javascript/v2/node_modules/tailwindcss/defaultTheme');

module.exports = {
  purge: [
    './app/javascript/v2/components/**/.{js,jsx}',
    './app/views/**/*.{js,erb,haml}'
  ],
  darkMode: false, // or 'media' or 'class'
  theme: {
    extend: {
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
