defmodule CommonUI.CSSHelpers do
  @moduledoc false
  @spec build_class(false | nil | binary | list, any) :: binary
  def build_class(list, joiner \\ " ")
  def build_class(string, _joiner) when is_binary(string), do: string
  def build_class([], _joiner), do: ""
  def build_class(nil, _joiner), do: ""
  def build_class(false, _joiner), do: ""

  def build_class(list, joiner) when is_list(list) do
    list
    # Recursively join with no extra spaces
    |> join_list_cleanly(joiner, [])
    # We are appending front to back so reverse
    |> :lists.reverse()
    # finally make into a single string
    |> IO.iodata_to_binary()
  end

  # Ignore the last value if it's bad, and remove the unneeded joiner
  defp join_list_cleanly([false], joiner, [joiner | acc]), do: acc
  defp join_list_cleanly([""], joiner, [joiner | acc]), do: acc
  defp join_list_cleanly([nil], joiner, [joiner | acc]), do: acc
  defp join_list_cleanly([{_val, false}], joiner, [joiner | acc]), do: acc

  # Ignore the last value if it's bad
  defp join_list_cleanly([false], _joiner, acc), do: acc
  defp join_list_cleanly([""], _joiner, acc), do: acc
  defp join_list_cleanly([nil], _joiner, acc), do: acc
  defp join_list_cleanly([{_val, false}], _joiner, acc), do: acc

  # the final join

  # if the final join is a list then just restart the joining with that list
  defp join_list_cleanly([value], joiner, acc) when is_list(value), do: join_list_cleanly(value, joiner, acc)

  # If the final value is anything else cast it to a string and trim it
  defp join_list_cleanly([{value, true}], _joiner, acc), do: [to_trimmed_string(value) | acc]
  defp join_list_cleanly([value], _joiner, acc), do: [to_trimmed_string(value) | acc]

  # ignore an empty string along the way
  defp join_list_cleanly(["" | rest], joiner, acc) do
    join_list_cleanly(rest, joiner, acc)
  end

  # ignore a nil along the way
  defp join_list_cleanly([nil | rest], joiner, acc) do
    join_list_cleanly(rest, joiner, acc)
  end

  # ignore false along the way
  defp join_list_cleanly([false | rest], joiner, acc) do
    join_list_cleanly(rest, joiner, acc)
  end

  defp join_list_cleanly([{_val, false} | rest], joiner, acc) do
    join_list_cleanly(rest, joiner, acc)
  end

  # If the value is a list then treat is a coming before the rest of the values.
  defp join_list_cleanly([value | rest], joiner, acc) when is_list(value) do
    value
    |> Enum.concat(rest)
    |> join_list_cleanly(joiner, acc)
  end

  # if the value is a tuple of a boolean and a class
  defp join_list_cleanly([{value, true} | rest], joiner, acc) do
    join_list_cleanly(rest, joiner, [joiner, to_trimmed_string(value) | acc])
  end

  # The default case
  defp join_list_cleanly([value | rest], joiner, acc) do
    join_list_cleanly(rest, joiner, [joiner, to_trimmed_string(value) | acc])
  end

  defp to_trimmed_string(value) when is_binary(value), do: String.trim(value)
  defp to_trimmed_string(value) when is_atom(value), do: Atom.to_string(value)
  defp to_trimmed_string(value), do: String.trim(to_string(value))
end
