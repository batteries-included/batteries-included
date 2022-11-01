const plugin = require('tailwindcss/plugin');
const colors = require('tailwindcss/colors');

const defaultTheme = require('tailwindcss/defaultTheme');

const typography = require('@tailwindcss/typography');
const forms = require('@tailwindcss/forms');
const daisy = require('daisyui');

// Grey for standard things
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
// The main accent color
// Use it sparingly
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
// A nice secondary color. However because its
// not as over powering it gets used as much as the
// primary
const astral = {
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
};
// An accent color
const blizardBlue = {
  50: '#FFFFFF',
  100: '#FFFFFF',
  200: '#FFFFFF',
  300: '#DEFAF8',
  400: '#BAF4F0',
  500: '#97EFE9',
  600: '#66E8DF',
  700: '#36E0D4',
  800: '#1EC0B5',
  900: '#169087',
};

// Action Only Color

// INFO
// info = blizardBlue
// success
const shamrock = {
  50: '#CDF4E5',
  100: '#BCF0DD',
  200: '#9AE9CC',
  300: '#79E2BB',
  400: '#57DAAA',
  500: '#36D399',
  600: '#26AB7A',
  700: '#1B7D59',
  800: '#114F38',
  900: '#072118',
};

// Warning
const seaBuckthorn = {
  50: '#FEF2DD',
  100: '#FDEAC9',
  200: '#FBDBA2',
  300: '#F9CC7B',
  400: '#F8BD54',
  500: '#F6AE2D',
  600: '#E1940A',
  700: '#AB7107',
  800: '#764D05',
  900: '#402A03',
};
// Error
const heath = {
  50: '#D42F40',
  100: '#C62939',
  200: '#A4222F',
  300: '#831B25',
  400: '#61141C',
  500: '#3F0D12',
  600: '#100305',
  700: '#000000',
  800: '#000000',
  900: '#000000',
};

module.exports = {
  content: [
    './js/**/*.js',
    '../lib/*.*ex',
    '../lib/**/*.*ex',
    '../../common_ui/lib/**/*.*ex',
    '../../../deps/petal_components/**/*.*ex',
  ],

  theme: {
    colors: {
      ...colors,
      'fuscous-gray': fuscousGray,
      gray: fuscousGray,
      'violet-red': violetRed,
      pink: violetRed,
      astral,
      primary: astral,
      secondary: violetRed,
      // Accent and INFO
      'blizzard-blue': blizardBlue,
      // Success
      shamrock,
      // warning
      'sea-buckthorn': seaBuckthorn,
      // Error
      heath,
    },
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
    },
  },
  daisyui: {
    themes: [
      {
        mytheme: {
          primary: astral[500],
          secondary: violetRed[500],
          accent: blizardBlue[500],
          neutral: fuscousGray[500],
          'base-100': '#FFFFFF',
          info: blizardBlue[500],
          success: shamrock[500],
          warning: seaBuckthorn[500],
          error: heath[300],
        },
      },
    ],
  },

  plugins: [
    typography,
    forms,
    daisy,
    plugin(({ addVariant }) =>
      addVariant('phx-no-feedback', ['.phx-no-feedback&', '.phx-no-feedback &'])
    ),
    plugin(({ addVariant }) =>
      addVariant('phx-click-loading', [
        '.phx-click-loading&',
        '.phx-click-loading &',
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant('phx-submit-loading', [
        '.phx-submit-loading&',
        '.phx-submit-loading &',
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant('phx-change-loading', [
        '.phx-change-loading&',
        '.phx-change-loading &',
      ])
    ),
  ],
};
