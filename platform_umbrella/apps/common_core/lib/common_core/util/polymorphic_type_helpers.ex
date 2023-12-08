defmodule CommonCore.Util.PolymorphicTypeHelpers do
  @moduledoc """
  Generic callback implementations and helpers for working with `CommonCore.Util.PolymorphicType`s.
  """

  @doc """
  The delegated implementation of the `Ecto.Type.cast/1` callback.

  Receives any type as input and returns a validated `module` struct.
  """
  @spec polymorphic_cast(map() | struct(), module(), atom()) :: {:ok, Ecto.Schema.t() | Ecto.Changeset.data()} | :error
  def polymorphic_cast(data, module, type)
  def polymorphic_cast(data, module, type) when is_struct(data), do: polymorphic_cast(Map.from_struct(data), module, type)

  def polymorphic_cast(data, module, type) do
    required = apply(module, :__required_fields, [])

    data
    |> changeset(module)
    |> Ecto.Changeset.put_change(:type, type)
    |> Ecto.Changeset.validate_required(required)
    |> apply_changeset_if_valid()
  end

  @doc """
  The delegated implementation of the `Ecto.Type.dump/1` callback.

  Receives the output of cast and outputs the ecto type. In this case, it is always a map.

  Removes virtual fields so they don't get put in the DB.
  """
  @spec polymorphic_dump(struct(), module(), atom()) :: {:ok, map()}
  def polymorphic_dump(data, module, type)

  def polymorphic_dump(data, module, _type) do
    {:ok,
     data
     |> remove_virtuals(module)
     |> Map.from_struct()}
  end

  @doc """
  The delegated implementation of the `Ecto.Type.load/1` callback.

  Receives data from DB and loads into `module` struct.
  """
  @spec polymorphic_load(map(), module(), atom()) :: {:ok, Ecto.Schema.t() | Ecto.Changeset.data()} | :error
  def polymorphic_load(data, module, _type) do
    data
    |> changeset(module)
    |> apply_changeset_if_valid()
  end

  @doc """
  Applies the changeset changes to the changeset data if the changeset is valid.

  Returns the schema type or a map if the changeset was created schemaless-ly.
  """
  @spec apply_changeset_if_valid(Ecto.Changeset.t()) :: {:ok, Ecto.Schema.t() | Ecto.Changeset.data()} | :error
  def apply_changeset_if_valid(cs) do
    case cs do
      %Ecto.Changeset{valid?: true} ->
        {:ok, Ecto.Changeset.apply_changes(cs)}

      _ ->
        :error
    end
  end

  @doc """
  Creates a changeset for the given data and module.

  Applies defaults if `CommonCore.Util.DefaultableField`s are used in the schema.
  """
  @spec changeset(keyword() | map(), module()) :: Ecto.Changeset.t()
  def changeset(data, module) do
    fields_for_changeset = module.__schema__(:fields) ++ module.__schema__(:virtual_fields)
    data = with_defaults(data, module)

    module
    |> struct([])
    |> Ecto.Changeset.cast(data, fields_for_changeset)
  end

  defp remove_virtuals(struct, module) do
    Enum.reduce(get_defaults(module), struct, fn {field, _default}, struct ->
      Map.delete(struct, field)
    end)
  end

  defp with_defaults(data, module) do
    module
    |> get_defaults()
    |> Enum.reduce(data, fn {field, default}, acc ->
      default_or_override(acc, field, default)
    end)
  end

  defp default_or_override(%{type: _type} = data, field, default) do
    default_or_override(data, field, default, String.to_existing_atom("#{field}_override"))
  end

  defp default_or_override(%{"type" => _type} = data, field, default) do
    default_or_override(data, Atom.to_string(field), default, "#{field}_override")
  end

  defp default_or_override(data, field, default, override) do
    Map.put(data, field, Map.get(data, override, default) || default)
  end

  defp get_defaults(module) do
    func = :__defaulted_fields

    if function_exported?(module, func, 0) do
      apply(module, func, [])
    else
      []
    end
  end
end
