locals_without_parens = [
  embeds_many: 3,
  field: 3,
  field: 2
]

[
  plugins: [Styler],
  import_deps: [:ecto],
  inputs: [
    "{mix,.formatter}.exs",
    "*.{heex,ex,exs}",
    "{lib,test}/**/*.{heex,ex,exs}"
  ],
  subdirectories: ["priv/*/migrations"],
  locals_without_parens: locals_without_parens
]
