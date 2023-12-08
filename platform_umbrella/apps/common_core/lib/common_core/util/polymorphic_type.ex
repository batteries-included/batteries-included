defmodule CommonCore.Util.PolymorphicType do
  @moduledoc false
  use Ecto.ParameterizedType

  alias CommonCore.Util.PolymorphicTypeHelpers
  alias Ecto.ParameterizedType

  defmacro __using__(opts) do
    case Keyword.fetch(opts, :type) do
      {:ok, type} ->
        [
          prelude(type),
          ecto_type_impl()
        ]

      :error ->
        raise "invalid instantiation: set :type option"
    end
  end

  defp prelude(type) do
    quote do
      use Ecto.Type

      import unquote(__MODULE__), only: [type_field: 0]

      @__polymorphic_type unquote(type)

      @before_compile {unquote(__MODULE__), :__before_compile__}
    end
  end

  defmacro __before_compile__(env) do
    quote do
      def __polymorphic_type, do: @__polymorphic_type
      def __required_fields, do: unquote(Module.get_attribute(env.module, :required_fields, []))
    end
  end

  @doc """
  Defines `:type` field based on the `:type` option passed to `init/1`.
  """
  defmacro type_field() do
    quote do
      field(:type, Ecto.Enum, values: [@__polymorphic_type], default: @__polymorphic_type)
    end
  end

  defp ecto_type_impl do
    quote do
      @impl Ecto.Type
      def type, do: :map

      @impl Ecto.Type
      def cast(data), do: PolymorphicTypeHelpers.polymorphic_cast(data, __MODULE__, @__polymorphic_type)

      @impl Ecto.Type
      def dump(data), do: PolymorphicTypeHelpers.polymorphic_dump(data, __MODULE__, @__polymorphic_type)

      @impl Ecto.Type
      def load(data), do: PolymorphicTypeHelpers.polymorphic_load(data, __MODULE__, @__polymorphic_type)

      defoverridable Ecto.Type
    end
  end

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

  # def dump(data, _dumper, %{mappings: mappings} = _params) do
  #   type = type_from(mappings, data)
  #   Ecto.Type.dump(type, data)
  # end

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
end
