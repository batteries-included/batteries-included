defmodule CommonCore.OpenApi.Schema do
  @moduledoc false
  defmacro __using__(_ots \\ []) do
    quote do
      use TypedEctoSchema

      @primary_key false

      def new(map), do: unquote(__MODULE__).schema_new(map, __MODULE__)
      def new!(map), do: with({:ok, value} <- new(map), do: value)

      def changeset(base_struct, args), do: unquote(__MODULE__).schema_changeset(args, base_struct)

      defoverridable new: 1, changeset: 2
    end
  end

  def schema_new(map, module) do
    module
    |> struct()
    |> module.changeset(map)
    |> Ecto.Changeset.apply_action(:update)
  end

  def schema_changeset(%{} = map, base) do
    struct = base.__struct__
    embeds = struct.__schema__(:embeds)
    fields = struct.__schema__(:fields)

    changeset = Ecto.Changeset.cast(base, map, fields -- embeds)

    Enum.reduce(embeds, changeset, fn embed_field, chg ->
      Ecto.Changeset.cast_embed(chg, embed_field)
    end)
  end
end
