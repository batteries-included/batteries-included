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
end
