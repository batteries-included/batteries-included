defmodule CommonCore.OpenApi.Schema do
  @moduledoc false
  defmacro __using__(_ots \\ []) do
    quote do
      use TypedEctoSchema

      @primary_key false

      def new(opts \\ []), do: unquote(__MODULE__).schema_new(__MODULE__, opts)
      def new!(opts \\ []), do: with({:ok, value} <- new(opts), do: value)

      def changeset(base_struct, args), do: unquote(__MODULE__).schema_changeset(base_struct, args)

      defoverridable new: 1, changeset: 2
    end
  end

  # Creates a new struct from the given module and applies a changeset
  # to update it with the given map.
  # Returns {:ok, struct} on success, {:error, changeset} on failure.
  @spec schema_new(module() | atom() | struct(), Keyword.t() | list() | map()) ::
          {:error, Ecto.Changeset.t()} | {:ok, map()}
  def schema_new(module, opts) do
    module
    |> struct()
    |> module.changeset(opts)
    |> Ecto.Changeset.apply_action(:update)
  end

  @spec schema_changeset(
          struct(),
          list() | map()
        ) :: struct()
  # Casts the given map to a changeset for the given base struct.
  #
  # Handles casting embedded schemas separately from regular fields.
  def schema_changeset(base, opts) do
    struct = base.__struct__
    embeds = struct.__schema__(:embeds)
    fields = struct.__schema__(:fields)

    changeset = Ecto.Changeset.cast(base, sanitize_opts(opts), fields -- embeds)

    Enum.reduce(embeds, changeset, fn embed_field, chg ->
      Ecto.Changeset.cast_embed(chg, embed_field)
    end)
  end

  # Ecto really wants to take in raw maps.
  # It doesn't want a keywork list
  # It doesn't want values of embedded fields to be structs
  #
  # So the below allows us to take in a map or a keyword list
  # then all the values are converted to maps deeply before
  # returning a map for Ecto.Changeset to work with.
  defp sanitize_opts(opts) do
    opts
    |> ensure_map()
    |> Map.new()
  end

  defp ensure_map(value) when is_list(value) do
    Enum.map(value, &ensure_map/1)
  end

  defp ensure_map(value) when is_struct(value) do
    value
    |> Map.from_struct()
    |> ensure_map()
  end

  defp ensure_map(%{} = value) do
    Map.new(value, fn {key, value} -> {key, ensure_map(value)} end)
  end

  defp ensure_map(value), do: value
end
