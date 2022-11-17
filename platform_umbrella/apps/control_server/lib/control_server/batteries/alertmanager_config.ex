defmodule ControlServer.Batteries.AlertmanagerConfig do
  use TypedEctoSchema
  import Ecto.Changeset

  alias KubeExt.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field(:image, :string, default: Defaults.Images.alertmanager_image())
    field(:version, :string, default: Defaults.Monitoring.alertmanager_version())
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, [:image, :version])
  end
end
