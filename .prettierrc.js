module.exports = {
  semi: true,
  singleQuote: true,
  trailingComma: 'es5',
  proseWrap: 'always',
  bracketSameLine: true,
  tabWidth: 2,
  overrides: [
    {
      files: ['static/**/*.html'],
      options: {
        parser: 'go-template',
      },
    },
  ],
};
