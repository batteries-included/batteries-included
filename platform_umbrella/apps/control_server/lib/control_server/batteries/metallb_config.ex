defmodule ControlServer.Batteries.MetalLBConfig do
  use TypedEctoSchema

  import Ecto.Changeset

  alias KubeExt.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field(:namespace, :string, default: Defaults.Namespaces.loadbalancer())
    field(:speaker_image, :string, default: Defaults.Images.metallb_speaker_image())
    field(:controller_image, :string, default: Defaults.Images.metallb_controller_image())
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, [:namespace, :speaker_image, :controller_image])
  end
end
