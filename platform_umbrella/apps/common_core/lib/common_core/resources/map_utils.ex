defmodule CommonCore.Resources.MapUtils do
  @moduledoc """
  Utility functions
  """

  @doc ~S"""

  Put `key` in `map` with `value` if `predicate` is `true`
  `predicate` may be a function that accepts the original map as its sole argument.

  Returns the original map if `predicate` is or evaluates to `false`.
  Returns the updated map if `predicate` is or evaluates to `true`

  ## Examples

      iex> CommonCore.Resources.MapUtils.maybe_put(%{}, true, "a", "b")
      %{"a" => "b"}

      iex> CommonCore.Resources.MapUtils.maybe_put(%{}, false, "a", "b")
      %{}

      iex> CommonCore.Resources.MapUtils.maybe_put(%{}, fn _original_map -> true end, "a", "b")
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

      iex> CommonCore.Resources.MapUtils.maybe_put_lazy(%{}, true, "a", fn _ -> "b" end)
      %{"a" => "b"}

      iex> CommonCore.Resources.MapUtils.maybe_put_lazy(%{}, false, "a", fn _ -> "b" end)
      %{}

      iex> CommonCore.Resources.MapUtils.maybe_put_lazy(%{}, fn _original_map -> true end, "a", fn _ -> "b" end)
      %{"a" => "b"}
  """
  @spec maybe_put_lazy(map(), boolean(), String.t(), (map() -> any())) :: map()
  def maybe_put_lazy(%{} = map, predicate, key, func) when is_boolean(predicate) and predicate,
    do: Map.put(map, key, func.(map))

  def maybe_put_lazy(%{} = map, predicate, _key, _func) when is_boolean(predicate) and not predicate, do: map

  @spec maybe_put_lazy(map(), (map() -> boolean()), String.t(), (map() -> any())) :: map()
  def maybe_put_lazy(%{} = map, predicate, key, func) when is_function(predicate),
    do: maybe_put_lazy(map, predicate.(map), key, func)
end
