const defaultTheme = require('tailwindcss/defaultTheme');

module.exports = {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  theme: {
    extend: {
      scale: {
        '-100': '-1',
      },
      colors: {
        primary: 'var(--bi-color-primary)',
        'primary-hover': 'var(--color-primary-hover)',
        'text-dark': 'var(--color-text-dark)',
        secondary: 'var(--bi-color-secondary)',
        'secondary-gray': 'var(--bi-color-secondary-gray)',
        accent: 'var(--bi-color-accent)',
        default: 'var(--bi-color-text-default)',
        muted: 'var(--bi-color-text-muted)',
        'raisin-black': '#181B22',
        'davys-grey': '#4E535F',
        'raisin-black-2': '#21242B',
        'rich-black': '#111318',
      },
      fontFamily: {
        sans: ['var(--bi-font-sans)', ...defaultTheme.fontFamily.sans],
        serif: ['var(--bi-font-serif)', ...defaultTheme.fontFamily.serif],
        heading: ['var(--bi-font-heading)', ...defaultTheme.fontFamily.sans],
      },
    },
  },
  plugins: [
    require('@tailwindcss/typography'),
    require('tailwindcss-animated'),
    require('@tailwindcss/forms'),
    function ({ addComponents }) {
      addComponents({
        //helpful for debugging UI/layouts, etc
        '.redz': {
          border: '2px dashed red',
        },
      });
    },
  ],
  darkMode: 'class',
};
