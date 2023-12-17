defmodule CommonCore.FerretDB.FerretService do
  @moduledoc false
  use TypedEctoSchema

  import CommonCore.Util.EctoValidations
  import Ecto.Changeset

  alias CommonCore.Util.Memory
  alias Ecto.Changeset

  @required_fields ~w(name instances postgres_cluster_id)a
  @optional_fields ~w(cpu_requested cpu_limits memory_requested memory_limits virtual_size)a

  @presets [
    %{
      name: "tiny",
      cpu_requested: nil,
      cpu_limits: 500,
      memory_requested: nil,
      memory_limits: Memory.mb_to_bytes(512)
    },
    %{
      name: "small",
      cpu_requested: nil,
      cpu_limits: 1000,
      memory_requested: Memory.mb_to_bytes(512),
      memory_limits: Memory.mb_to_bytes(1024)
    },
    %{
      name: "large",
      cpu_requested: 4000,
      cpu_limits: 4000,
      memory_requested: Memory.gb_to_bytes(2),
      memory_limits: Memory.gb_to_bytes(2)
    },
    %{
      name: "huge",
      cpu_requested: 8000,
      cpu_limits: 8000,
      memory_requested: Memory.gb_to_bytes(24),
      memory_limits: Memory.gb_to_bytes(24)
    }
  ]

  @timestamps_opts [type: :utc_datetime_usec]
  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "ferret_services" do
    field :name, :string
    field :instances, :integer
    field :cpu_requested, :integer
    field :cpu_limits, :integer
    field :memory_requested, :integer
    field :memory_limits, :integer

    belongs_to :postgres_cluster, CommonCore.Postgres.Cluster

    # Used in the CRUD form. User picks a "Size", which sets other fields based on presets.
    field :virtual_size, :string, virtual: true

    timestamps()
  end

  def presets, do: @presets

  def preset_by_name(name), do: Enum.find(@presets, fn p -> p.name == name end)

  def preset_options_for_select, do: Enum.map(@presets, &{String.capitalize(&1.name), &1.name}) ++ [{"Custom", "custom"}]

  @doc false
  def changeset(ferret_service, attrs) do
    fields = @required_fields ++ @optional_fields

    ferret_service
    |> cast(attrs, fields)
    |> validate_required(@required_fields)
    |> maybe_set_virtual_size()
    |> downcase_fields([:name])
  end

  @spec maybe_set_virtual_size(Ecto.Changeset.t()) :: any()
  def maybe_set_virtual_size(changeset) do
    changeset
    |> apply_preset(get_field(changeset, :virtual_size))
    |> maybe_deduce_virtual_size()
  end

  defp maybe_deduce_virtual_size(changeset) do
    with nil <- Changeset.get_field(changeset, :virtual_size),
         true <- find_matching_preset(changeset) != nil do
      put_change(changeset, :virtual_size, find_matching_preset(changeset))
    else
      _ ->
        changeset
    end
  end

  defp find_matching_preset(changeset) do
    # Finds the preset that matches the values in the changeset.
    #
    # Returns the `:name` of the matched preset, or `nil` if no match.
    @presets
    |> Enum.find(
      %{},
      fn preset ->
        # Check if all keys are either the name which we ignore
        # or they are euqal to the current changeset value.
        Enum.all?(preset, fn {k, v} -> k == :name || get_field(changeset, k) == v end)
      end
    )
    |> Map.get(:name, nil)
  end

  defp apply_preset(changeset, nil), do: changeset
  defp apply_preset(changeset, "custom" = _preset_name), do: changeset

  defp apply_preset(changeset, preset_name) do
    preset = preset_by_name(preset_name)

    # Add all preset fields to changeset
    Enum.reduce(preset, changeset, fn
      {k, _v}, acc when k == :name ->
        acc

      {k, _v}, acc when k == "name" ->
        acc

      {k, v}, acc ->
        put_change(acc, k, v)
    end)
  end
end
