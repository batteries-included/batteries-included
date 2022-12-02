# Used by "mix format"
locals_without_parens = [
  plug: 1
]

[
  inputs: [
    "{mix,.formatter}.exs",
    "*.{ex,exs}",
    "{lib,test}/**/*.{ex,exs}"
  ],
  locals_without_parens: locals_without_parens
]
