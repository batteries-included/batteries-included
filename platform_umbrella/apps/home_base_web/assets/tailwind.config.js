const colors = require("tailwindcss/colors");

const defaultTheme = require("tailwindcss/defaultTheme");

const fuscous_gray = {
  50: "#f6f6f6",
  100: "#eeeeed",
  200: "#d3d4d3",
  300: "#b9b9b9",
  400: "#858584",
  500: "#50514F",
  600: "#484947",
  700: "#3c3d3b",
  800: "#30312f",
  900: "#272827",
};
module.exports = {
  purge: ["../lib/**/*.ex", "../lib/**/*.leex", "../lib/**/*.eex", "./js/**/*.js"],
  darkMode: false, // or 'media' or 'class'
  theme: {
    colors: {
      ...colors,
      perfume: {
        50: "#fcfbfe",
        100: "#f9f8fd",
        200: "#efedfa",
        300: "#e5e3f7",
        400: "#d2cdf1",
        500: "#BEB8EB",
        600: "#aba6d4",
        700: "#8f8ab0",
        800: "#726e8d",
        900: "#5d5a73",
      },
      "algae-green": {
        50: "#f9fefc",
        100: "#f3fdfa",
        200: "#e2f9f2",
        300: "#d1f6ea",
        400: "#aeefdb",
        500: "#8BE8CB",
        600: "#7dd1b7",
        700: "#68ae98",
        800: "#538b7a",
        900: "#447263",
      },
      "fuscous-gray": fuscous_gray,
      gray: fuscous_gray,
      "violet-red": {
        50: "#fff5f9",
        100: "#ffecf3",
        200: "#fecfe2",
        300: "#feb3d1",
        400: "#fd79ae",
        500: "#fc408b",
        600: "#e33a7d",
        700: "#bd3068",
        800: "#972653",
        900: "#7b1f44",
      },
      astral: {
        50: "#f4f8fa",
        100: "#e9f2f6",
        200: "#c8dee7",
        300: "#a7cad9",
        400: "#66a3bd",
        500: "#247BA0",
        600: "#206f90",
        700: "#1b5c78",
        800: "#164a60",
        900: "#123c4e",
      },
    },
    extend: {
      fontFamily: {
        sans: ["Inter var", ...defaultTheme.fontFamily.sans],
      },
    },
  },
  variants: {
    extend: {},
  },
  plugins: [require("@tailwindcss/typography")],
};
