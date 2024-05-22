defmodule CommonUI.Helpers.Parser do
  @moduledoc """
  This the the parser syntax that Md.Parser will use.

  Essentially this is our markdown grammar. We can restrict
  what is allowed in the markdown content by defining the syntax
  here.

  This module is used in the `CommonUI.Components.Markdown` module
  to parse markdown content.
  """

  use Md.Parser

  alias Md.Parser.Syntax.Void

  @default_syntax Map.put(Void.syntax(), :settings, Void.settings())

  @custom_syntax %{
    comment: [{"<!--", %{closing: "-->"}}],
    paragraph: [
      # Notice that all the header tags are kicked up one value
      {"#", %{tag: :h2}},
      {"##", %{tag: :h3}},
      {"###", %{tag: :h4}}
    ],
    list: [{"- ", %{tag: :li, outer: :ul}}],
    brace: [
      {"*", %{tag: :b}},
      {"_", %{tag: :i}},
      {"~", %{tag: :s}},
      {"`", %{tag: :code, mode: :raw, attributes: %{class: "code-inline"}}}
    ],
    block: [
      {"```", %{tag: [:pre, :code], pop: %{code: [attribute: :class, prefixes: ["", "lang-"]]}}}
    ]
  }

  @syntax Map.merge(@default_syntax, @custom_syntax)
end
