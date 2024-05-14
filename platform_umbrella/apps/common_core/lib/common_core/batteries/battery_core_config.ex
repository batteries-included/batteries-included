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

    defaultable_field :bootstrap_image, :string, default: Defaults.Images.bootstrap_image()
    defaultable_field :image, :string, default: Defaults.Images.control_server_image()

    secret_field :secret_key
    field :cluster_type, Ecto.Enum, values: [:kind, :aws, :provided], default: :kind
    field :default_size, Ecto.Enum, values: [:tiny, :small, :medium, :large, :xlarge, :huge]
    field :cluster_name, :string

    field :server_in_cluster, :boolean, default: false

    # This is the install id that the control server is reporting to
    # It shouldn't be nil. However we can't make it required before
    # InstallSpec from Install is fixed.
    field :install_id, CommonCore.Ecto.BatteryUUID, default: nil
  end
end
