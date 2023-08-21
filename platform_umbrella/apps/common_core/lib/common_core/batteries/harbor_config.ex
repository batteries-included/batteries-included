defmodule CommonCore.Batteries.HarborConfig do
  @moduledoc false
  use TypedEctoSchema

  import Ecto.Changeset

  alias CommonCore.Defaults
  alias CommonCore.Defaults.RandomKeyChangeset

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

    field :csrf_key, :string
    field :harbor_admin_password
    field :secret, :string
    field :registry_credential_password, :string
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
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
    |> RandomKeyChangeset.maybe_set_random(:csrf_key)
    |> RandomKeyChangeset.maybe_set_random(:secret)
    |> RandomKeyChangeset.maybe_set_random(:harbor_admin_password, length: 12)
    |> RandomKeyChangeset.maybe_set_random(:registry_credential_password, length: 12)
  end
end
