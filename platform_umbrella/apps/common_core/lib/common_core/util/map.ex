defmodule CommonCore.Util.Map do
  @moduledoc """
  Utility functions for working with maps
  """

  @doc """
  Put `key` in `map` with `value` if `value` is not an empty string or empty map.
  Returns the original map if `value` is an empty string or empty map.

  ### Examples

        iex> CommonCore.Util.Map.maybe_put(%{}, "a", "b")
        %{"a" => "b"}

        iex> CommonCore.Util.Map.maybe_put(%{}, "a", "")
        %{}

        iex> CommonCore.Util.Map.maybe_put(%{}, "a", %{})
        %{}

        iex> CommonCore.Util.Map.maybe_put(%{}, "", "b")
        %{}
  """

  @spec maybe_put(map(), String.t(), integer() | list(any()) | String.t() | map() | nil) :: map()
  def maybe_put(map, _key, value) when value == "", do: map
  def maybe_put(map, _key, value) when value == %{}, do: map
  def maybe_put(map, key, _value) when key == "", do: map

  def maybe_put(map, key, value) do
    if value do
      Map.put(map, key, value)
    else
      map
    end
  end

  @doc ~S"""

  Put `key` in `map` with `value` if `predicate` is `true`
  `predicate` may be a function that accepts the original map as its sole argument.

  Returns the original map if `predicate` is or evaluates to `false`.
  Returns the updated map if `predicate` is or evaluates to `true`

  ## Examples

      iex> CommonCore.Util.Map.maybe_put(%{}, true, "a", "b")
      %{"a" => "b"}

      iex> CommonCore.Util.Map.maybe_put(%{}, false, "a", "b")
      %{}

      iex> CommonCore.Util.Map.maybe_put(%{}, fn _original_map -> true end, "a", "b")
      %{"a" => "b"}
  """
  @spec maybe_put(map(), boolean(), String.t(), String.t()) :: map()
  def maybe_put(map, predicate, key, value)

  def maybe_put(%{} = map, predicate, key, value) when is_boolean(predicate) and predicate, do: Map.put(map, key, value)

  def maybe_put(%{} = map, predicate, _key, _value) when is_boolean(predicate) and not predicate, do: map

  @spec maybe_put(map(), (map() -> boolean()), String.t(), String.t()) :: map()
  def maybe_put(%{} = map, predicate, key, value) when is_function(predicate),
    do: maybe_put(map, predicate.(map), key, value)

  @doc """

  Lazily put `key` in `map` with the result of `func` if `predicate` is `true`
  `predicate` may be a function that accepts the original map as its sole argument.
  `func` will also be passed the original map as its sole argument.

  Returns the original map if `predicate` is or evaluates to `false`.
  Returns the updated map if `predicate` is or evaluates to `true`

  ## Examples

      iex> CommonCore.Util.Map.maybe_put_lazy(%{}, true, "a", fn _ -> "b" end)
      %{"a" => "b"}

      iex> CommonCore.Util.Map.maybe_put_lazy(%{}, false, "a", fn _ -> "b" end)
      %{}

      iex> CommonCore.Util.Map.maybe_put_lazy(%{}, fn _original_map -> true end, "a", fn _ -> "b" end)
      %{"a" => "b"}
  """
  @spec maybe_put_lazy(map(), boolean(), String.t(), (map() -> any())) :: map()
  def maybe_put_lazy(%{} = map, predicate, key, func) when is_boolean(predicate) and predicate,
    do: Map.put(map, key, func.(map))

  def maybe_put_lazy(%{} = map, predicate, _key, _func) when is_boolean(predicate) and not predicate, do: map

  @spec maybe_put_lazy(map(), (map() -> boolean()), String.t(), (map() -> any())) :: map()
  def maybe_put_lazy(%{} = map, predicate, key, func) when is_function(predicate),
    do: maybe_put_lazy(map, predicate.(map), key, func)

  @doc """
  Append `value` to the list value of `key` if `predicate` is `true`.
  Will create list if the value is `nil`.
  `predicate` may be a function that accepts the original map as its sole argument.

  ## Examples

    iex> CommonCore.Util.Map.maybe_append(%{key: ["a"]}, true, :key, "b")
    %{key: ["a","b"]}

    iex> CommonCore.Util.Map.maybe_append(%{key: ["a"]}, true, :key, ["b", "c"])
    %{key: ["a","b","c"]}

    iex> CommonCore.Util.Map.maybe_append(%{}, true, :key, "b")
    %{key: ["b"]}

    iex> CommonCore.Util.Map.maybe_append(%{key: ["a"]}, false, :key, "b")
    %{key: ["a"]}

    iex> CommonCore.Util.Map.maybe_append(%{key: ["a"]}, fn _original_map -> true end, :key, "b")
    %{key: ["a", "b"]}

  """

  @spec maybe_append(map(), boolean() | (map() -> boolean()), String.t(), term()) :: map()
  def maybe_append(%{} = map, predicate, key, val) when not is_list(val), do: maybe_append(map, predicate, key, [val])

  @spec maybe_append(map(), boolean(), String.t(), list(term())) :: map()
  def maybe_append(%{} = map, predicate, key, val) when is_boolean(predicate) and predicate,
    do: Map.put(map, key, (map[key] || []) ++ val)

  def maybe_append(%{} = map, predicate, _key, _val) when is_boolean(predicate) and not predicate, do: map

  @spec maybe_append(map(), (map() -> boolean()), String.t(), list(term())) :: map()
  def maybe_append(%{} = map, predicate, key, val) when is_function(predicate),
    do: maybe_append(map, predicate.(map), key, val)
end
