const path = require('path');

const postcss_import = {
  addModulesDirectories: [
    // This is needed to resolve the current working directory modules (-_-)
    path.resolve('node_modules'),
  ],
};

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
    'postcss-import': postcss_import,
    'postcss-url': postcss_url,
    '@tailwindcss/postcss': {},
    // 'cssnano': { preset: 'default' },
  },
};
