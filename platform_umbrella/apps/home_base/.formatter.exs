[
  import_deps: [:ecto],
  inputs: [
    "{mix,.formatter}.exs",
    "*.{ex,exs}",
    "priv/*/seeds.exs",
    "{lib,test}/**/*.{ex,exs}"
  ],
  subdirectories: ["priv/*/migrations"]
]
