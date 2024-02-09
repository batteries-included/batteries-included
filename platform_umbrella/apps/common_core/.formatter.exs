locals_without_parens = [
  defaultable_field: 3,
  embeds_many: 3,
  field: 3,
  field: 2
]

[
  plugins: [Styler],
  import_deps: [:ecto, :typed_struct],
  inputs: [
    "{mix,.formatter}.exs",
    "*.{heex,ex,exs}",
    "{lib,test}/**/*.{heex,ex,exs}"
  ],
  locals_without_parens: locals_without_parens
]
