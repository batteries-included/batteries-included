defmodule CommonCore.Batteries.CertManagerConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Ecto.Schema

  batt_polymorphic_schema type: :cert_manager do
    defaultable_image_field :acmesolver_image, image_id: :cert_manager_acmesolver
    defaultable_image_field :cainjector_image, image_id: :cert_manager_cainjector
    defaultable_image_field :controller_image, image_id: :cert_manager_controller
    defaultable_image_field :webhook_image, image_id: :cert_manager_webhook

    field :email, :string
  end

  @ctl_keys_to_drop ~w(ctl_image ctl_image_name_override ctl_image_tag_override)a
  def load(data) do
    data
    |> Map.drop(@ctl_keys_to_drop ++ Enum.map(@ctl_keys_to_drop, &Atom.to_string/1))
    |> then(&Schema.schema_load(__MODULE__, &1))
  end
end
