[
  import_deps: [:phoenix, :ecto, :typed_struct],
  plugins: [Phoenix.LiveView.HTMLFormatter, Styler],
  inputs: [
    "{mix,.formatter,.credo}.exs",
    "config/*.exs"
  ],
  subdirectories: ["apps/*"]
]
