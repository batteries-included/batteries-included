// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const path = require('path');
const plugin = require('tailwindcss/plugin');
const colors = require('tailwindcss/colors');
const defaultTheme = require('tailwindcss/defaultTheme');
const forms = require('@tailwindcss/forms');
const typography = require('@tailwindcss/typography');
const daisyui = require('daisyui');

const _primary = {
  300: '#FFA8CB',
  400: '#FC408B',
  500: '#DE2E74',
};

const _gray = {
  100: '#DADADA',
  200: '#CCCCCC',
  300: '#999A9F',
  400: '#7F7F7F',
  500: '#545155',
  600: '#38383A',
  700: '#1C1C1E',
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
  important: '.common-ui',
  content: [
    // Use absolute paths so this config can be shared between umbrella apps
    path.resolve(__dirname, 'js/**/*.js'),
    path.resolve(__dirname, '../lib/**/*.*ex*'),
    path.resolve(__dirname, '../storybook/**/*.*ex*'),
    path.resolve(__dirname, '../../control_server_web/assets/js/**/*.js'),
    path.resolve(
      __dirname,
      '../../control_server_web/lib/control_server_web/**/*.*ex*'
    ),
    path.resolve(__dirname, '../../home_base_web/assets/js/**/*.js'),
    path.resolve(__dirname, '../../home_base_web/lib/home_base_web/**/*.*ex*'),
    path.resolve(__dirname, '../../../deps/petal_components/**/*.*ex*'),
  ],
  theme: {
    // Note when changing: keep `storybook/colors.story.exs` up to date
    extend: {
      colors: {
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
        blue: blizardBlue,
        // Petal Components
        primary: violetRed,
        secondary: blizardBlue,
        success: shamrock,
        danger: colors.red,
        warning: seaBuckthorn,
        info: blizardBlue,
        gray: colors.zinc,
      },
      fontFamily: {
        sans: ['"Inter Variable"', ...defaultTheme.fontFamily.sans],
        mono: ['"JetBrains Mono Variable"', ...defaultTheme.fontFamily.mono],
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
          neutral: '#3D4451',
          'base-100': colors.white,
          info: astral[200],
          success: shamrock[500],
          warning: seaBuckthorn[500],
          error: heath[500],
        },
      },
    ],
  },
  plugins: [
    forms,
    typography,
    daisyui,

    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
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
