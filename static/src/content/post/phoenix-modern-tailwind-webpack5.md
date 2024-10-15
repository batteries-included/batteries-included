---
title: 'Phoenix with latest tailwind and webpack'
excerpt:
  Phoenix is a fantastic framework that we use and love at Batteries Included
publishDate: 2021-06-24
tags: ['phoenix', 'js', 'javascript', 'elixir', 'tailwind', 'css']
image: ./covers/post-9.jpg
draft: false
---

## Editor's Note

> Later versions of Phoenix do not require this. The pages is kept for
> historical reasons only. Please upgrade to a newer version.

Phoenix is a fantastic framework that we use and love at Batteries Included. We
also really love tailwind CSS. So using both with the latest up-to-date software
is essential to us. Below is a quick write-up on how we've modified the default
phoenix install to use Webpack 5 and [TailwindCSS](https://tailwindcss.com/).

# Starting Point

```bash
mix archive.install hex phx_new 1.5.9
mix phx.new --live example_upgrade
cd example_upgrade
```

# Upgrade Versions

Next, we need to get the js dependencies to be compatible with webpack5 and
TailwindCSS. Some software will need updated versions, while others won't be
compatible with newer Webpack, and others won't be useful with Tailwind.

Let's first remove the things that we're not going to use anymore. We're going
to use Tailwind, which uses CSS and PostCSS for styling. Since sass has gone
through several version upgrades and we're not going to rely on it actively, I'm
going to remove it rather than ensuring that I don't break things.

```bash
cd assests
npm remove sass-loader node-sass \
  hard-source-webpack-plugin \
  optimize-css-assets-webpack-plugin
```

Next, I want to upgrade all the Webpack things. Webpack 5 was a breaking change
that will require some elixir code changes. First, let's upgrade. Here I'm going
to use a utility and upgrade all the dependencies to know the latest versions.
You can upgrade however you want.

```bash
npm i -g npm-check-updates
ncu -u webpack webpack-cli terser-webpack-plugin \
  css-loader copy-webpack-plugin \
  babel-loader mini-css-extract-plugin \
  "@babel/preset-env" "@babel/core"
npm i
```

# Add on Tailwind and PostCSS

Before making changes to `webpack.config.js`, let's install the tailwind
dependencies and build tools. These are all generating code in the final CSS so
that they can be dev dependencies.

```bash
npm i tailwindcss @tailwindcss/typography \
  autoprefixer postcss postcss-loader \
  postcss-import css-minimizer-webpack-plugin --save-dev
```

# Change Webpack Config

`webpack.config.js` needs to be changed since we're drastically changing build
versions and tools. First, terser became part of the build, and other CSS/js
optimization plugins haven't been needed or updated for this version, so let's
make the necessary changes.

For example, the setting `devtool` needs an updated in Webpack 5. That line
becomes:

```js
devtool: devMode ? 'source-map' : undefined,
```

Terser became part of the main Webpack build. Since there's no longer a need to
configure that and sourcemaps, we can significantly simplify the optimization
setting.

```js
    optimization: {
      minimizer: ['...', new CssMinimizerPlugin()],
    },
```

We want to use post CSS and Tailwind; we'll need to change the module settings
to include PostCSS and the file types we expect.

For me, the CSS loader was configured like this previously:

```js
    module: {
      rules: [
        {
          test: /\.js$/,
          exclude: /node_modules/,
          use: {
            loader: 'babel-loader'
          }
        },
        {
          test: /\.[s]?css$/,
          use: [
            MiniCssExtractPlugin.loader,
            'css-loader',
            'sass-loader',
          ],
        }
      ]
    },
```

We're not going to use sass, and we do want SVG and post sass. The end result
for me is that the module rules become:

```js
    module: {
      rules: [
        {
          test: /\.js$/,
          exclude: /node_modules/,
          use: {
            loader: 'babel-loader',
          },
        },
        {
          test: /\.[s]?css$/,
          use: [MiniCssExtractPlugin.loader, 'css-loader', 'postcss-loader'],
        },
        {
          test: /\.svg$/i,
          type: 'asset/inline',
        },
        {
          test: /\.(png|jpg|jpeg|gif)$/i,
          type: 'asset/resource',
        },
        {
          test: /\.(woff|woff2|eot|ttf|otf)$/i,
          type: 'asset/resource',
        },
      ],
    },
```

The key changes were:

- Change to CSS file type
- Remove sass loader
- Add PostCSS loader
- Add on image and font file types

The plugins section and mode section need small tweaks becoming:

```js
    plugins: [
      new MiniCssExtractPlugin({ filename: '../css/app.css' }),
      new CopyWebpackPlugin({
        patterns: [{ from: 'static/', to: '../' }],
      }),
    ],

```

# Finalize Changes

`app.scss` needs to be `app.css` and we need to include Tailwind. We'll also
need to clean up sass leftovers and renames.

```sh
# Move the file
mv css/app.scss css/app.css

# Remove the sass imports
sed -i '/@import/d' css/app.css

# Add the Tailwind imports
echo "$(
  echo "@import 'tailwindcss/base'"
  cat css/app.css
)" > css/app.css
echo "$(
  echo "@import 'tailwindcss/components'"
  cat css/app.css
)" > css/app.css
echo "$(
  echo "@import 'tailwindcss/utilities'"
  cat css/app.css
)" > css/app.css

# Reflect the new name in the js
sed -i 's/scss/css/g' js/app.js
```

Also, add the `NODE_ENV` environment variable when building the production
version of our style and javascript assets. We'll need to change the scripts
field in the `package.json` file to do all of this. That will end up looking
like this:

```js
  "scripts": {
    "deploy": "NODE_ENV=production webpack --mode production",
    "watch": "webpack --mode development --watch"
  },
```

# PostCSS and Tailwind

Tailwind and PostCSS both need some configs. Let us create those. For PostCSS I
am going to add `assets/postcss.config.js` that looks like this:

```js
module.exports: {
  plugins: {
    'postcss-import': {},
    tailwindcss: {},
    autoprefixer: {},
  },
};
```

Then for Tailwind, I'm going to add a file `assets/tailwind.config.js` that
should look like:

```js
const typography: require("@tailwindcss/typography");

module.exports: {
  mode: "jit",
  purge: [
    "./js/**/*.js",
    "./js/**/*.ts",
    "../lib/**/*.ex",
    "../lib/**/*.leex",
    "../lib/**/*.eex",
    "../lib/**/*.sface",
  ],
  darkMode: false,
  plugins: [typography],
};
```

The above code sets the defaults; You can add your colors or add other tailwind
plugins as you see fit. This config does use the tailwind jit, which we've found
to be faster but a little prone to missing a new class being added.

# Building

That should be good enough to get everything builds. Check that by running the
production build.

```sh
npm run deploy
```

If that works then we're all good to go for the next steps.

# Dev Server STDIN

Webpack changed the command line arguments for its watch and compile mode. That
feature is used during development, and we're going to need to make changes to
the Phoenix endpoint in dev.

Currently, there should be a config in `config/dev.exs` inside there is a key
for configuring the static watchers.

## Before

```elixir
config :example_upgrade, ExampleUpgradeWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode",
      "development",
      "--watch-stdin",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]
```

## After

```elixir
config :example_upgrade, ExampleUpgradeWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode=development",
      "--watch",
      "--watch-options-stdin",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]
```

Notice how `mode` is now equal to development, and we're watching and watching
options-stdin the changes are subtle but essential.

# Done

With everything all done, you should be good to go. Webpack 5 should be running
and integrated with phoenix. TailwindCSS should be usable and purged if unused.
We've put the result of the upgrade up in a repository here:
[example_phoenix](https://github.com/batteries-included/example_phoenix). Each
commit should be one step in the process above.
