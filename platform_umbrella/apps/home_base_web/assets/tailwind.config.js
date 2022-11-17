const plugin = require('tailwindcss/plugin');

const defaultTheme = require('tailwindcss/defaultTheme');

const typography = require('@tailwindcss/typography');
const forms = require('@tailwindcss/forms');
const flowbite = require('flowbite/plugin');

// Grey for standard things
const heavyMetal = {
  50: '#C9CAC8',
  100: '#BFC0BD',
  200: '#AAACA9',
  300: '#969894',
  400: '#82847F',
  500: '#6D6F6B',
  600: '#595B57',
  700: '#444643',
  800: '#30312F',
  900: '#141414',
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
// not as over powering it gets used as the
// primary color in UI's
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
// const blizardBlue = {
//   50: '#FFFFFF',
//   100: '#FFFFFF',
//   200: '#FFFFFF',
//   300: '#DEFAF8',
//   400: '#BAF4F0',
//   500: '#97EFE9',
//   600: '#66E8DF',
//   700: '#36E0D4',
//   800: '#1EC0B5',
//   900: '#169087',
// };

// success
// SUCCESS
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
// WARNING
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
// ERROR
// FATAL
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
    // Include flowbite
    './node_modules/flowbite/**/*.js',
    // This project hooks and js
    './js/**/*.js',

    // All the templates in
    // this umbrella project
    '../lib/*.*ex',
    '../lib/**/*.*ex',
    // Common UI
    '../../common_ui/lib/*.*ex',
    '../../common_ui/lib/**/*.*ex',
  ],

  theme: {
    colors: {
      'heavy-metal': heavyMetal,
      'violet-red': violetRed,
      astral,
      // Accent and INFO
      'blizzard-blue': blizardBlue,
      // Success
      shamrock,
      // warning
      'sea-buckthorn': seaBuckthorn,
      // Error
      heath,

      // Base Renames
      pink: violetRed,
      gray: heavyMetal,
      blue: blizardBlue,

      // Action renames
      primary: astral,
      secondary: violetRed,
      success: shamrock,
      warning: seaBuckthorn,
      error: heath,
    },
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
    },
  },

  plugins: [
    typography,
    forms,
    flowbite,
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
