defmodule CommonCore.Batteries.BatteryCoreConfig do
  @moduledoc false

  use CommonCore, {:embedded_schema, no_encode: [:secret_key]}

  alias CommonCore.Defaults

  @required_fields ~w(cluster_type)a

  batt_polymorphic_schema type: :battery_core do
    field :core_namespace, :string, default: Defaults.Namespaces.core()
    field :base_namespace, :string, default: Defaults.Namespaces.base()
    field :data_namespace, :string, default: Defaults.Namespaces.data()
    field :ai_namespace, :string, default: Defaults.Namespaces.ai()

    secret_field :secret_key
    field :cluster_type, Ecto.Enum, values: [:kind, :aws, :provided], default: :kind
    field :default_size, Ecto.Enum, values: [:tiny, :small, :medium, :large, :xlarge, :huge]
    field :cluster_name, :string

    field :server_in_cluster, :boolean, default: false

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
    # Time in UTC when the upgrade can start take place
    field :upgrade_start_hour, :integer, default: 18
    field :upgrade_end_hour, :integer, default: 23
  end
end
