defmodule CommonCore.Batteries.BatteryCoreConfig do
  @moduledoc false

  use CommonCore, {:embedded_schema, no_encode: [:secret_key]}

  alias CommonCore.Defaults
  alias CommonCore.Ecto.Schema
  alias CommonCore.Installs.Options
  alias CommonCore.Util.Time

  @required_fields ~w(cluster_type)a

  batt_polymorphic_schema type: :battery_core do
    field :core_namespace, :string, default: Defaults.Namespaces.core()
    field :base_namespace, :string, default: Defaults.Namespaces.base()
    field :data_namespace, :string, default: Defaults.Namespaces.data()
    field :ai_namespace, :string, default: Defaults.Namespaces.ai()

    secret_field :secret_key
    field :cluster_type, Ecto.Enum, values: Keyword.values(Options.providers()), default: :kind
    field :default_size, Ecto.Enum, values: Options.sizes()
    field :cluster_name, :string

    # The decalared usage of the cluster
    field :usage, Ecto.Enum, values: Keyword.values(Options.usages()), default: :development

    # This is the install id that the control server is reporting to
    # It shouldn't be nil. However we can't make it required before
    # InstallSpec from Install is fixed.
    field :install_id, CommonCore.Ecto.BatteryUUID, default: nil
    field :control_jwk, :map, redact: true, default: nil

    # When the control server can upgrade to a new version
    # Monday: 0
    # Tuesday: 1
    # Wednesday: 2
    # Thursday: 3
    # Friday: 4
    # Saturday: 5
    # Sunday: 6
    field :upgrade_days_of_week, {:array, :boolean}, default: [true, true, true, true, false, false, false]
    field :virtual_upgrade_days_of_week, {:array, :string}, default: [], virtual: true

    # Time in UTC when the upgrade can start take place
    field :upgrade_start_hour, :integer, default: 18
    field :upgrade_end_hour, :integer, default: 23
  end

  def changeset(%__MODULE__{} = config, attrs) do
    config
    |> Schema.schema_changeset(attrs)
    |> put_upgrade_days_of_week_from_virtual()
  end

  @doc """
  The config stores the upgrade days of the week as an array of booleans.
  This converts the array of day names that comes from the config UI form
  to the array of booleans and back as needed.
  """
  def put_upgrade_days_of_week_from_virtual(changeset) do
    if virtual_upgrade_days_of_week = get_change(changeset, :virtual_upgrade_days_of_week) do
      upgrade_days_of_week = Enum.map(Time.days_of_week(), &Enum.member?(virtual_upgrade_days_of_week, &1))

      put_change(changeset, :upgrade_days_of_week, upgrade_days_of_week)
    else
      put_virtual_from_upgrade_days_of_week(changeset)
    end
  end

  defp put_virtual_from_upgrade_days_of_week(changeset) do
    upgrade_days_of_week = get_field(changeset, :upgrade_days_of_week)

    virtual_upgrade_days_of_week =
      upgrade_days_of_week
      |> Enum.with_index()
      |> Enum.map(fn {value, index} -> if(value, do: Enum.at(Time.days_of_week(), index)) end)
      |> Enum.reject(&is_nil(&1))

    put_change(changeset, :virtual_upgrade_days_of_week, virtual_upgrade_days_of_week)
  end
end
