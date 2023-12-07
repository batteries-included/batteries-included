locals_without_parens = [
  polymorphic_embeds_one: 2,
  attr: 2,
  attr: 3,
  defaultable_field: 3,
  slot: 1,
  slot: 2,
  slot: 3
]

[
  import_deps: [:phoenix, :ecto, :typed_struct],
  plugins: [Phoenix.LiveView.HTMLFormatter, Styler],
  inputs: [
    "{mix,.formatter,.credo}.exs",
    "config/*.exs"
  ],
  subdirectories: ["apps/*"],
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens]
]
