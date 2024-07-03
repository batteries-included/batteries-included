// .prettierrc.mjs
/** @type {import("prettier").Config} */
const config = {
  plugins: ['prettier-plugin-astro'],
  overrides: [
    {
      files: '*.astro',
      options: {
        parser: 'astro',
      },
    },
  ],
  semi: true,
  singleQuote: true,
  trailingComma: 'es5',
  proseWrap: 'always',
  bracketSameLine: true,
  tabWidth: 2,
};

export default config;
