locals_without_parens = [
  polymorphic_embeds_one: 2
]

[
  import_deps: [:ecto],
  inputs: [
    "{mix,.formatter}.exs",
    "*.{heex,ex,exs}",
    "priv/*/seeds.exs",
    "{lib,test}/**/*.{heex,ex,exs}"
  ],
  subdirectories: ["priv/*/migrations"],
  locals_without_parens: locals_without_parens
]
