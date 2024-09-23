defmodule CommonUI.TextHelpers do
  @moduledoc false
  @default_length 48
  @default_omission "..."

  @doc """
  This is a method to effiently truncate a string to a length with elipsis added.
  """
  def truncate(text, opts \\ []) do
    max_length = Keyword.get(opts, :length, @default_length)
    omission = Keyword.get(opts, :omission, @default_omission)

    cond do
      not String.valid?(text) ->
        text

      String.length(text) < max_length ->
        text

      true ->
        length_with_omission = max_length - String.length(omission)

        # Do the final cut and copy.
        "#{String.slice(text, 0, length_with_omission)}#{omission}"
    end
  end

  @doc """
  This is a method to obfuscate a string by replacing a chunk in the middle with asterisks.
  """
  def obfuscate(text, opts \\ [])

  def obfuscate(nil, _opts) do
    ""
  end

  def obfuscate(text, opts) do
    keep = Keyword.get(opts, :keep, 4)
    char = Keyword.get(opts, :char, "*")
    char_limit = Keyword.get(opts, :char_limit, 30)

    if String.length(text) <= keep * 2 do
      text
    else
      left = String.slice(text, 0..(keep - 1))
      right = String.slice(text, -keep..-1)

      mid_count = String.length(text) - keep * 2
      mid = String.duplicate(char, min(char_limit, mid_count))

      left <> mid <> right
    end
  end
end
