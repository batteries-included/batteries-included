locals_without_parens = [
  polymorphic_embeds_one: 2,
  embeds_many: 3,
  field: 3,
  field: 2
]

[
  import_deps: [:ecto],
  inputs: [
    "{mix,.formatter}.exs",
    "*.{heex,ex,exs}",
    "{lib,test}/**/*.{heex,ex,exs}"
  ],
  locals_without_parens: locals_without_parens
]
