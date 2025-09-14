defmodule CommonCore.Util.Map do
  @moduledoc """
  Utility functions for working with maps
  """

  @considered_empty ["", %{}, 0, "0"]

  @doc """
  Put `key` in `map` with `value` if `value` is not an empty string or empty map or zero.
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
  def maybe_put(map, _key, value) when value in @considered_empty, do: map
  def maybe_put(map, key, _value) when key in @considered_empty, do: map

  def maybe_put(map, key, value) do
    if value, do: Map.put(map, key, value), else: map
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

  @doc """
  Converts an Ecto struct to a plain map, removing internal Ecto metadata.

  This function strips out:
  - `:__meta__` - Ecto's internal metadata for tracking database state
  - Association fields - References to related schemas
  - Virtual fields - Fields that exist only in memory, not in the database

  This is useful for serialization or when you need a clean map representation
  of your struct data without Ecto's internal tracking information.

  ## Examples

      # With a basic schema created via batt_schema
      iex> schema = %CommonCore.ExampleSchemas.EmbeddedMetaSchema{name: "John", age: 25}
      iex> CommonCore.Util.Map.from_struct(schema)
      %{name: "John", age: 25, password: nil}

      # Regular maps are passed through unchanged
      iex> CommonCore.Util.Map.from_struct(%{name: "Jane", age: 30})
      %{name: "Jane", age: 30}

      # Non-Ecto structs are converted to maps
      iex> CommonCore.Util.Map.from_struct(%URI{scheme: "https", host: "example.com"})
      %{scheme: "https", host: "example.com", path: nil, query: nil, fragment: nil, port: nil, authority: nil, userinfo: nil}

  """
  @spec from_struct(struct() | map()) :: map()
  def from_struct(i) when is_struct(i) do
    # Get the association fields, convert to map, then drop association metadata

    struct = Map.get(i, :__struct__, nil)

    # Only try to get schema info if the struct actually has the __schema__ function
    {assocs, virtual_fields} =
      if struct && function_exported?(struct, :__schema__, 1) do
        {struct.__schema__(:associations), struct.__schema__(:virtual_fields)}
      else
        {[], []}
      end

    i
    |> Map.from_struct()
    |> Map.drop([:__meta__ | assocs ++ virtual_fields])
  end

  def from_struct(i), do: i
end
