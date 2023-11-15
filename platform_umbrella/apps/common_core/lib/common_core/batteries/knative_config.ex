defmodule CommonCore.Batteries.KnativeConfig do
  @moduledoc false
  use TypedEctoSchema

  import Ecto.Changeset

  alias CommonCore.Defaults

  @required_fields ~w()a
  @optional_fields ~w(operator_image webhook_image namespace)a

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :operator_image, :string, default: Defaults.Images.knative_operator_image()
    field :webhook_image, :string, default: Defaults.Images.knative_operator_webhook_image()
    field :namespace, :string, default: Defaults.Namespaces.knative()
  end

  def changeset(struct, params \\ %{}) do
    fields = Enum.concat(@required_fields, @optional_fields)

    struct
    |> cast(params, fields)
    |> validate_required(@required_fields)
  end
end
