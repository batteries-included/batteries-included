defmodule CommonCore.Batteries.HarborConfig do
  use TypedEctoSchema
  import Ecto.Changeset

  alias CommonCore.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :core_image, :string, default: Defaults.Images.harbor_core_image()
    field :ctl_image, :string, default: Defaults.Images.harbor_ctl_image()
    field :jobservice_image, :string, default: Defaults.Images.harbor_jobservice_image()
    field :exporter_image, :string, default: Defaults.Images.harbor_exporter_image()
    field :photon_image, :string, default: Defaults.Images.harbor_photon_image()
    field :portal_image, :string, default: Defaults.Images.harbor_portal_image()
    field :trivy_adapter_image, :string, default: Defaults.Images.harbor_trivy_adapter_image()

    field :csrf_key, :string, default: "XXXXX"
    field :harbor_admin_password, :string, default: "============="
    field :secret, :string, default: "------------------"
    field :registry_credential_password, :string, default: "_________________"
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, [
      :core_image,
      :ctl_image,
      :jobservice_image,
      :photon_image,
      :portal_image,
      :trivy_adapter_image,
      :csrf_key,
      :harbor_admin_password,
      :secret,
      :registry_credential_password
    ])
  end
end
