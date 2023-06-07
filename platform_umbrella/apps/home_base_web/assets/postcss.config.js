module.exports = {
  plugins: {
    'postcss-import': {},
    'tailwindcss/nesting': {},
    tailwindcss: {},
    // Include autoprefixer if we are in production
    ...(process.env.NODE_ENV === 'production' ? { autoprefixer: {} } : {}),
    // Include cssnano if we are in production
    ...(process.env.NODE_ENV === 'production' ? { cssnano: {} } : {}),
  },
};
