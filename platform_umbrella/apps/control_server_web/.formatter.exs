locals_without_parens = [
  defaultable_field: 3,
  defaultable_field: 2,
  slug_field: 2,
  slug_field: 1,
  secret_field: 2,
  secret_field: 1,
  batt_embedded_schema: 2,
  batt_embedded_schema: 1,
  batt_polymorphic_schema: 2,
  batt_schema: 3,
  batt_schema: 2,
  embeds_many: 3,
  field: 3,
  field: 2
]

[
  import_deps: [:phoenix],
  plugins: [Phoenix.LiveView.HTMLFormatter, Styler],
  inputs: ["*.exs", "{config,lib,test}/**/*.{heex,ex,exs}", "priv/*/seeds.exs"],
  subdirectories: ["priv/*/migrations"],
  locals_without_parens: locals_without_parens
]
