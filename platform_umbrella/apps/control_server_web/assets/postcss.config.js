module.exports = {
  loader: {
    '.woff': 'file',
    '.woff2': 'file',
  },
  plugins: {
    'postcss-import': {},
    'postcss-url': [
      {
        filter: '**/*.woff2',
        url: 'copy',
        useHash: true,
      },
    ],
    'tailwindcss/nesting': {},
    tailwindcss: {},
    // Include autoprefixer if we are in production
    ...(process.env.NODE_ENV === 'production' ? { autoprefixer: {} } : {}),
    // Include cssnano if we are in production
    ...(process.env.NODE_ENV === 'production' ? { cssnano: {} } : {}),
  },
};
