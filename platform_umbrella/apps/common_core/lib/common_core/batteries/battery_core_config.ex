defmodule CommonCore.Batteries.BatteryCoreConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :battery_core
  use CommonCore.Util.DefaultableField
  use TypedEctoSchema

  import CommonCore.Util.PolymorphicTypeHelpers
  import Ecto.Changeset, only: [validate_required: 2]

  alias CommonCore.Defaults
  alias CommonCore.Defaults.RandomKeyChangeset

  @required_fields ~w()a

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    defaultable_field :core_namespace, :string, default: Defaults.Namespaces.core()
    defaultable_field :base_namespace, :string, default: Defaults.Namespaces.base()
    defaultable_field :data_namespace, :string, default: Defaults.Namespaces.data()
    defaultable_field :ml_namespace, :string, default: Defaults.Namespaces.ml()

    defaultable_field :image, :string, default: Defaults.Images.control_server_image()
    field :secret_key, :string

    defaultable_field :server_in_cluster, :boolean, default: false
    type_field()
  end

  @impl Ecto.Type
  def cast(data) do
    data
    |> changeset(__MODULE__)
    |> RandomKeyChangeset.maybe_set_random(:secret_key)
    |> validate_required(@required_fields)
    |> apply_changeset_if_valid()
  end
end
