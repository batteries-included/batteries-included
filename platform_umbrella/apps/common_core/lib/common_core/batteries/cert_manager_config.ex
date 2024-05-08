defmodule CommonCore.Batteries.CertManagerConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Defaults

  batt_polymorphic_schema type: :cert_manager do
    defaultable_field :acmesolver_image, :string, default: Defaults.Images.cert_manager_acmesolver_image()
    defaultable_field :cainjector_image, :string, default: Defaults.Images.cert_manager_cainjector_image()
    defaultable_field :controller_image, :string, default: Defaults.Images.cert_manager_controller_image()
    defaultable_field :ctl_image, :string, default: Defaults.Images.cert_manager_ctl_image()
    defaultable_field :webhook_image, :string, default: Defaults.Images.cert_manager_webhook_image()

    field :email, :string
  end
end
