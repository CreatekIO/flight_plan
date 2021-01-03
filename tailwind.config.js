module.exports = {
  purge: [
    './app/javascript/v2/components/**/.{js,jsx}',
    './app/views/**/*.{js,erb,haml}'
  ],
  darkMode: false, // or 'media' or 'class'
  theme: {
    extend: {},
  },
  variants: {
    extend: {},
  },
  plugins: [],
}
