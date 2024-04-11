const defaultTheme = require('tailwindcss/defaultTheme');
const forms = require('@tailwindcss/forms');
const typography = require('@tailwindcss/typography');

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

const success = {
  light: '#79E2BB',
  DEFAULT: '#36D399',
  dark: '#26AB7A',
};

const warning = {
  light: '#FBDBA2',
  DEFAULT: '#F6AE2D',
  dark: '#E1940A',
};

const error = {
  light: '#FEE2E2',
  DEFAULT: '#ED4C5C',
  dark: '#991B1B',
};

const gray = {
  lightest: '#FAFAFA',
  lighter: '#DADADA',
  light: '#999A9F',
  DEFAULT: '#7F7F7F',
  dark: '#545155',
  darker: '#38383A',
  darkest: '#1C1C1E',
};

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        primary,
        secondary,
        success,
        warning,
        error,
        gray,
      },
      fontFamily: {
        sans: ['"Inter Variable"', ...defaultTheme.fontFamily.sans],
        mono: ['"JetBrains Mono Variable"', ...defaultTheme.fontFamily.mono],
      },
    },
  },
  plugins: [forms, typography],
};
