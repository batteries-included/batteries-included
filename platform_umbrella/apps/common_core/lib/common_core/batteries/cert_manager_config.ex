defmodule CommonCore.Batteries.CertManagerConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :cert_manager
  use CommonCore.Util.DefaultableField
  use TypedEctoSchema

  alias CommonCore.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    defaultable_field :acmesolver_image, :string, default: Defaults.Images.cert_manager_acmesolver_image()
    defaultable_field :cainjector_image, :string, default: Defaults.Images.cert_manager_cainjector_image()
    defaultable_field :controller_image, :string, default: Defaults.Images.cert_manager_controller_image()
    defaultable_field :ctl_image, :string, default: Defaults.Images.cert_manager_ctl_image()
    defaultable_field :webhook_image, :string, default: Defaults.Images.cert_manager_webhook_image()

    type_field()
  end
end
