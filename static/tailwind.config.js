const defaultTheme = require('tailwindcss/defaultTheme');
const forms = require('@tailwindcss/forms');
const typography = require('@tailwindcss/typography');
const animated = require('tailwindcss-animated');

const primary = {
  light: '#FFA8CB',
  DEFAULT: '#FC408B',
  dark: '#DE2E74',
};

const secondary = {
  light: '#DEFAF8',
  DEFAULT: '#97EFE9',
  dark: '#36E0D4',
};

const gray = {
  lightest: '#FAFAFA',
  lighter: '#DADADA',
  light: '#999A9F',
  DEFAULT: '#7F7F7F',
  dark: '#545155',
  darker: '#38383A',
  darkest: '#1C1C1E',
  // Used for dark mode
  'darker-tint': '#4E535F',
  'darkest-tint': '#21242B',
};

module.exports = {
  theme: {
    content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
    extend: {
      colors: {
        primary,
        secondary,
        gray,
      },
      fontFamily: {
        sans: ['"Inter Variable"', ...defaultTheme.fontFamily.sans],
        mono: ['"JetBrains Mono Variable"', ...defaultTheme.fontFamily.mono],
      },
    },
  },
  plugins: [typography, animated, forms],
};
