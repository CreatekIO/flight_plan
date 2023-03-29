const defaultTheme = require('tailwindcss/defaultTheme');
const colors = require('tailwindcss/colors');

module.exports = {
  content: [
    './app/packs/{components,demos}/**/*.{js,jsx}',
    './app/views/**/*.{html,js}.*'
  ],
  safelist: [{ pattern: /task-list-item/ }],
  theme: {
    extend: {
      colors: {
        green: colors.emerald,
        yellow: colors.amber,
        purple: colors.violet,
        github: {
          green: '#6cc644',
          red: '#bd2c00',
          purple: '#6e5494'
        },
        'harvest-orange': '#f36c00'
      },
      fontFamily: {
        sans: ['Lato', ...defaultTheme.fontFamily.sans]
      },
      animation: {
        'toast-in': 'toast-slide-in 150ms linear both',
        'toast-out': 'toast-slide-out 150ms linear both'
      },
      keyframes: theme => {
        // Corresponds to `w-64` + `right-2` - keep in sync with Notifications.jsx
        const transform = `translateX(${theme('spacing.64')} + ${theme('spacing.2')})`;
        const nullTransform = `translateX(0)`;

        return {
          'toast-slide-in': {
            from: {
              visibility: 'visible',
              transform
            },
            to: {
              transform: nullTransform
            }
          },
          'toast-slide-out': {
            from: {
              transform: nullTransform
            },
            to: {
              visibility: 'hidden',
              transform
            }
          }
        };
      },
      typography: theme => ({
        DEFAULT: {
          css: {
            color: theme('colors.gray.900'),
            maxWidth: null,
            'a': {
              textDecoration: null
            },
            'table': {
              marginTop: '1em',
              marginBottom: '1em'
            },
            'p > img': {
              margin: 0,
              display: 'inline'
            },
            'li.task-list-item::before': {
              display: 'none'
            },
            'code::before': {
              content: null
            },
            'code::after': {
              content: null
            }
          }
        },
        sm: {
          css: {
            lineHeight: theme('lineHeight.normal'),
            // using !important so that we don't have to override
            // all the fiddly selectors for first/last-child etc.
            'ul ul, ul ol, ol ul, ol ol': {
              marginTop: '0 !important',
              marginBottom: '0 !important'
            },
            'ul li, ol li': {
              marginTop: '0 !important',
              marginBottom: '0 !important'
            }
          }
        }
      })
    }
  },
  plugins: [
    require('@tailwindcss/typography')
  ],
}
