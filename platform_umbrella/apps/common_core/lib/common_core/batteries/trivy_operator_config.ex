defmodule CommonCore.Batteries.TrivyOperatorConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Defaults.Images

  batt_polymorphic_schema type: :trivy_operator do
    # the operator image
    defaultable_image_field :image, image_id: :trivy_operator
    # the node collector image
    defaultable_image_field :node_collector_image, image_id: :aqua_node_collector
    # the OCI bundle containing the checks
    defaultable_image_field :trivy_checks_image, image_id: :aqua_trivy_checks

    # the trivy scanner image repo and tag
    defaultable_field :trivy_repo, :string, default: :aqua_trivy |> Images.get_image!() |> Map.get(:name)
    defaultable_field :trivy_version_tag, :string, default: :aqua_trivy |> Images.get_image!() |> Map.get(:default_tag)
  end
end
