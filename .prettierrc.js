module.exports = {
  semi: true,
  singleQuote: true,
  trailingComma: 'es5',
  proseWrap: 'always',
  overrides: [
    {
      files: ['static/**/*.html'],
      options: {
        parser: 'go-template',
      },
    },
  ],
};
