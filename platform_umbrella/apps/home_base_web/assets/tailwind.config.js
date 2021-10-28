const colors = require('tailwindcss/colors');

const defaultTheme = require('tailwindcss/defaultTheme');

const typography = require('@tailwindcss/typography');

const fuscousGray = {
  50: '#f6f6f6',
  100: '#eeeeed',
  200: '#d3d4d3',
  300: '#b9b9b9',
  400: '#858584',
  500: '#50514F',
  600: '#484947',
  700: '#3c3d3b',
  800: '#30312f',
  900: '#272827',
};
const violetRed = {
  50: '#fff5f9',
  100: '#ffecf3',
  200: '#fecfe2',
  300: '#feb3d1',
  400: '#fd79ae',
  500: '#fc408b',
  600: '#e33a7d',
  700: '#bd3068',
  800: '#972653',
  900: '#7b1f44',
};
module.exports = {
  mode: 'jit',
  purge: [
    './js/**/*.js',
    '../lib/**/*.ex',
    '../lib/**/*.leex',
    '../lib/**/*.heex',
    '../lib/**/*.eex',
    '../lib/**/*.sface',
    '../../common_ui/lib/**/*.sface',
    '../../common_ui/lib/**/*.ex',
    '../../common_ui/lib/**/*.leex',
    '../../common_ui/lib/**/*.heex',
  ],
  darkMode: false, // or 'media' or 'class'
  theme: {
    colors: {
      ...colors,
      'fuscous-gray': fuscousGray,
      gray: fuscousGray,
      'violet-red': violetRed,
      pink: violetRed,
      astral: {
        50: '#f4f8fa',
        100: '#e9f2f6',
        200: '#c8dee7',
        300: '#a7cad9',
        400: '#66a3bd',
        500: '#247BA0',
        600: '#206f90',
        700: '#1b5c78',
        800: '#164a60',
        900: '#123c4e',
      },
    },
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
    },
  },
  variants: {
    extend: {},
  },
  plugins: [typography],
};
