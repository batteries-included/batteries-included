locals_without_parens = [
  attr: 2,
  attr: 3,
  slot: 1,
  slot: 2,
  slot: 3
]

[
  import_deps: [:phoenix],
  plugins: [Phoenix.LiveView.HTMLFormatter, Styler],
  inputs: [
    "{lib,test}/**/*.{heex,ex,exs}",
    "priv/*/seeds.exs",
    "storybook/**/*.exs",
    "*.{heex,ex,exs}",
    "{mix,.formatter}.exs"
  ],
  subdirectories: ["priv/*/migrations"],
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens]
]
