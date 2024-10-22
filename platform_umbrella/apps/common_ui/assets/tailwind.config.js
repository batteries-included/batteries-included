// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const path = require('path');
const plugin = require('tailwindcss/plugin');
const colors = require('tailwindcss/colors');
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
  content: [
    // Use absolute paths so this config can be shared between umbrella apps
    path.resolve(__dirname, 'js/**/*.js'),
    path.resolve(__dirname, '../lib/**/*.{heex,ex}'),
    path.resolve(__dirname, '../storybook/**/*.exs'),
    path.resolve(__dirname, '../../control_server_web/assets/js/**/*.js'),
    path.resolve(__dirname, '../../control_server_web/lib/**/*.{heex,ex}'),
    path.resolve(__dirname, '../../home_base_web/assets/js/**/*.js'),
    path.resolve(__dirname, '../../home_base_web/lib/**/*.{heex,ex}'),
  ],
  theme: {
    // Note when changing: keep `storybook/colors.story.exs` up to date
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
      backgroundImage: {
        caret: `url("data:image/svg+xml,%3csvg viewBox='0 0 9 6' fill='%23999A9F' xmlns='http://www.w3.org/2000/svg'%3e%3cpath d='M1.023,1.537L2.934,3.637L4.101,4.926C4.596,5.469 5.399,5.469 5.894,4.926L8.978,1.537C9.383,1.092 9.091,0.333 8.525,0.333L5.185,0.333L1.476,0.333C0.904,0.333 0.618,1.092 1.023,1.537Z' /%3e%3c/svg%3e")`,
      },
    },
  },
  plugins: [
    forms,
    typography,

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
    plugin(({ addVariant }) =>
      addVariant('slider-thumb', [
        '&::-webkit-slider-thumb',
        '&::-moz-range-thumb',
      ])
    ),
  ],
};
