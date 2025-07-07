const postcss_url = [
  {
    url: 'copy',
    useHash: true,
    filter: /\.(woff|woff2)$/,
  },
];

module.exports = {
  // Keep plugins in order!
  plugins: {
    'postcss-import': {},
    'postcss-url': postcss_url,
    '@tailwindcss/postcss': {},
  },
};
