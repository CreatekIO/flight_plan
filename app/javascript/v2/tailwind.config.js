const defaultTheme = require('tailwindcss/defaultTheme');

module.exports = {
  purge: [
    './app/javascript/v2/components/**/.{js,jsx}',
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
      }
    }
  },
  variants: {
    extend: {
      display: ['group-hover']
    }
  },
  plugins: [
      require('@tailwindcss/typography')
  ],
}
