defmodule ControlServer.Batteries.GiteaConfig do
  use TypedEctoSchema
  import Ecto.Changeset

  alias KubeExt.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field(:image, :string, default: Defaults.Images.gitea_image())
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, [:image])
  end
end
