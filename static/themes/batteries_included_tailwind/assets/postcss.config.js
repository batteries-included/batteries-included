const themeDir = __dirname + '/../';
const assetsDir = __dirname;
const tailwindConfig =
  process.env.HUGO_FILE_TAILWIND_CONFIG_JS || assetsDir + '/tailwind.config.js';
const tailwind = require('tailwindcss')(tailwindConfig);
const autoprefixer = require('autoprefixer')({ path: [themeDir] });

const purgecss = require('@fullhuman/postcss-purgecss')({
  // see https://gohugo.io/hugo-pipes/postprocess/#css-purging-with-postcss
  content: ['./hugo_stats.json', themeDir + '../../hugo_stats.json'],
  safelist: [/type/],
  defaultExtractor: (content) => {
    let els = JSON.parse(content).htmlElements;
    return els.tags.concat(els.classes, els.ids);
  },
});

module.exports = {
  // eslint-disable-next-line no-process-env
  plugins: [
    tailwind,
    autoprefixer,
    ...(process.env.HUGO_ENVIRONMENT === 'production' ? [purgecss] : []),
    ...(process.env.HUGO_ENVIRONMENT === 'production' ? [autoprefixer] : []),
  ],
};
