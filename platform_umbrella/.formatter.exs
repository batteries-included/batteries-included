[
  import_deps: [:phoenix, :ecto, :typed_struct],
  plugins: [Phoenix.LiveView.HTMLFormatter, Styler],
  inputs: ["mix.exs", "config/*.exs"],
  subdirectories: ["apps/*"]
]
