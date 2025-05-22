defmodule CommonCore.Batteries.TrivyOperatorConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  batt_polymorphic_schema type: :trivy_operator do
    defaultable_image_field :image, image_id: :trivy_operator
    defaultable_image_field :node_collector_image, image_id: :aqua_node_collector
    defaultable_image_field :trivy_checks_image, image_id: :aqua_trivy_checks

    defaultable_field :version_tag, :string, default: "0.62.1"
  end
end
