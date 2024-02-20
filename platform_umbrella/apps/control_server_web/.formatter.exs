[
  import_deps: [:phoenix],
  plugins: [Phoenix.LiveView.HTMLFormatter, Styler],
  inputs: ["*.exs", "{config,lib,storybook,test}/**/*.{heex,ex,exs}", "priv/*/seeds.exs"],
  subdirectories: ["priv/*/migrations"]
]
