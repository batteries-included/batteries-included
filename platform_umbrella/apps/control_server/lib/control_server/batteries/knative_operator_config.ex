defmodule ControlServer.Batteries.KnativeOperatorConfig do
  use TypedEctoSchema
  import Ecto.Changeset
  alias KubeExt.Defaults.Images

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field(:operator_image, :string, default: Images.knative_operator_image())
    field(:webhook_image, :string, default: Images.knative_operator_webhook_image())
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, [:operator_image, :webhook_image])
  end
end
