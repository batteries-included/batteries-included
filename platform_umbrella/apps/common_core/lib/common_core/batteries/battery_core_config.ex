defmodule CommonCore.Batteries.BatteryCoreConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :battery_core
  use CommonCore.Util.DefaultableField
  use TypedEctoSchema

  import CommonCore.Util.EctoValidations
  import CommonCore.Util.PolymorphicTypeHelpers
  import Ecto.Changeset, only: [validate_required: 2]

  alias CommonCore.Defaults

  @required_fields ~w(cluster_type)a

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    defaultable_field :core_namespace, :string, default: Defaults.Namespaces.core()
    defaultable_field :base_namespace, :string, default: Defaults.Namespaces.base()
    defaultable_field :data_namespace, :string, default: Defaults.Namespaces.data()
    defaultable_field :ml_namespace, :string, default: Defaults.Namespaces.ml()

    defaultable_field :bootstrap_image, :string, default: Defaults.Images.bootstrap_image()
    defaultable_field :image, :string, default: Defaults.Images.control_server_image()
    field :secret_key, :string
    field :cluster_type, Ecto.Enum, values: [:kind, :aws, :provided], default: :kind
    field :default_size, Ecto.Enum, values: [:tiny, :small, :medium, :large, :xlarge, :huge]
    field :cluster_name, :string

    defaultable_field :server_in_cluster, :boolean, default: false
    type_field()
  end

  @impl Ecto.Type
  def cast(data) do
    data
    |> changeset(__MODULE__)
    |> maybe_set_random(:secret_key)
    |> validate_required(@required_fields)
    |> apply_changeset_if_valid()
  end
end
