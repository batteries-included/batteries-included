defmodule CommonCore.Projects.RemovalTool do
  @moduledoc false

  @type removal :: list(atom() | number())
  @type removals :: list(removal())

  @doc """
  Removes the specified fields from a struct.

  Each removal i
  """
  @spec remove(struct() | map(), removals()) :: map() | struct()
  def remove(struct, removals) do
    removals
    |> Enum.map(fn removal ->
      {Enum.slice(removal, 0, length(removal) - 1), List.last(removal)}
    end)
    |> Enum.group_by(fn {path, _} -> path end, fn {_, to_remove} -> to_remove end)
    |> Enum.sort_by(fn {path, _} -> length(path) end)
    |> Enum.reduce(struct, fn {path, to_remove}, acc ->
      do_remove(acc, {path, to_remove})
    end)
  end

  defp do_remove(struct, {path, to_remove}) when path == [] do
    # update_in doesn't take an empty path so we need to handle this case
    # separately
    inner_remove(struct, to_remove)
  end

  defp do_remove(struct, {path, to_remove}) do
    update_in(struct, to_access(path), fn value ->
      inner_remove(value, to_remove)
    end)
  end

  defp inner_remove(value, to_remove) do
    case value do
      nil ->
        nil

      v when is_list(v) ->
        v |> Enum.with_index() |> Enum.reject(fn {_, i} -> i in to_remove end) |> Enum.map(fn {v, _} -> v end)

      _ ->
        Map.drop(value, to_remove)
    end
  end

  defp to_access(path) do
    Enum.map(path, fn
      i when is_integer(i) -> Access.at(i)
      a when is_atom(a) -> Access.key(a)
    end)
  end
end
