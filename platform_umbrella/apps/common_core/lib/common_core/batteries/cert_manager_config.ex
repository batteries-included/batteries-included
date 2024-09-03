defmodule CommonCore.Batteries.CertManagerConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  batt_polymorphic_schema type: :cert_manager do
    defaultable_image_field :acmesolver_image, image_id: :cert_manager_acmesolver
    defaultable_image_field :cainjector_image, image_id: :cert_manager_cainjector
    defaultable_image_field :controller_image, image_id: :cert_manager_controller
    defaultable_image_field :ctl_image, image_id: :cert_manager_ctl
    defaultable_image_field :webhook_image, image_id: :cert_manager_webhook

    field :email, :string
  end
end
