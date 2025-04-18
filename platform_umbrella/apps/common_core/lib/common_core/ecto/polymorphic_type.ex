defmodule CommonCore.Ecto.PolymorphicType do
  @moduledoc false
  use Ecto.ParameterizedType

  alias CommonCore.Ecto.PolymorphicType
  alias Ecto.ParameterizedType

  # for dialyzer
  @type t() :: map() | Ecto.Schema.t() | nil

  @impl ParameterizedType
  def init(opts) do
    case validate(opts) do
      {:error, errors} ->
        raise "invalid initialization: #{inspect(errors)}"

      _ ->
        nil
    end

    Map.new(opts)
  end

  @impl ParameterizedType
  def cast(nil, _), do: {:ok, nil}

  def cast(%module{} = data, _params) do
    Ecto.Type.cast(module, data)
  end

  def cast(data, %{mappings: mappings, field: field} = _params) do
    case type_from(mappings, data) do
      {:ok, type} ->
        # TODO: understand why params are not passed to Ecto.Type.cast
        Ecto.Type.cast(type, data)

      :error ->
        {:error, [{field, "no matching type in mappings"}]}
    end
  end

  @impl ParameterizedType
  # receives ecto type and return the db type
  def dump(nil, _dumper, _params), do: {:ok, nil}

  def dump(%module{} = data, dumper, _params) do
    Ecto.Type.dump(module, data, dumper)
  end

  @impl ParameterizedType
  # receives db value and returns ecto type
  def load(nil, _, _), do: {:ok, nil}

  def load(value, loader, %{mappings: mappings} = _params) do
    case type_from(mappings, value) do
      {:ok, type} ->
        Ecto.Type.load(type, value, loader)

      :error ->
        :error
    end
  end

  @impl ParameterizedType
  def type(_params), do: :map

  defp type_from(mappings, type) when is_map(mappings) and is_atom(type), do: Map.fetch(mappings, type)
  defp type_from(mappings, type) when is_atom(type), do: Keyword.fetch(mappings, type)
  defp type_from(mappings, type) when is_binary(type), do: type_from(mappings, String.to_existing_atom(type))
  defp type_from(mappings, %{type: type}), do: type_from(mappings, type)
  defp type_from(mappings, %{"type" => type}), do: type_from(mappings, type)
  # this indicates that a mapping was missed or something try to fail moderately loudly
  defp type_from(_mappings, _type), do: :error

  defp validate(opts) do
    if !Keyword.has_key?(opts, :mappings) do
      {:error, ["missing type mappings (:mappings)"]}
    end
  end

  @doc """
  Returns the mappings for the polymorphic type.

  ## Examples

  Assuming this schema:

      defmodule MySchema do
        use CommonCore, :schema

        def my_mappings(), do: [foo: CommonCore.Batteries.BatteryCoreConfig, bar: CommonCore.Batteries.BatteryCAConfig]
        batt_schema "my_schema" do
          field :config, PolymorphicType, mappings: my_mappings()
        end
      end

  Here are some examples of using `mappings/2` with it:

      CommonCore.Ecto.PolymorphicType.mappings(MySchema, :config)
      #=> [foo: CommonCore.Batteries.BatteryCoreConfig, bar: CommonCore.Batteries.BatteryCAConfig]

  """
  @spec mappings(module() | struct() | map(), atom()) :: keyword(String.t() | integer())
  def mappings(schema_or_struct_or_types, field)

  def mappings(%module{}, field), do: mappings(module, field)

  def mappings(schema, field) when is_atom(schema) do
    schema.__changeset__()
  rescue
    _ in UndefinedFunctionError ->
      raise ArgumentError, "#{inspect(schema)} is not an Ecto schema or types map"
  else
    %{} = types -> mappings(types, field)
  end

  def mappings(types, field) when is_map(types) do
    case types do
      %{^field => {:parameterized, {PolymorphicType, %{mappings: mappings}}}} -> mappings
      %{^field => {_, {:parameterized, {PolymorphicType, %{mappings: mappings}}}}} -> mappings
      %{^field => _} -> raise ArgumentError, "#{field} is not an PolymorphicType field"
      %{} -> raise ArgumentError, "#{field} does not exist"
    end
  end
end
