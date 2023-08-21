defmodule CommonCore.Batteries.BatteryCoreConfig do
  @moduledoc false
  use TypedEctoSchema

  import Ecto.Changeset

  alias CommonCore.Defaults
  alias CommonCore.Defaults.RandomKeyChangeset

  @optional_fields [
    :core_namespace,
    :base_namespace,
    :data_namespace,
    :ml_namespace,
    :image,
    :secret_key,
    :server_in_cluster
  ]
  @required_fields []

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :core_namespace, :string, default: Defaults.Namespaces.core()
    field :base_namespace, :string, default: Defaults.Namespaces.base()
    field :data_namespace, :string, default: Defaults.Namespaces.data()
    field :ml_namespace, :string, default: Defaults.Namespaces.ml()

    field :image, :string, default: Defaults.Images.control_server_image()
    field :secret_key, :string

    field :server_in_cluster, :boolean, default: false
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @optional_fields ++ @required_fields)
    |> RandomKeyChangeset.maybe_set_random(:secret_key)
  end
end
