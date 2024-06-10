defmodule CommonCore.Batteries.TrivyOperatorConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Defaults

  batt_polymorphic_schema type: :trivy_operator do
    defaultable_field :image, :string, default: Defaults.Images.trivy_operator_image()
    defaultable_field :node_colletor_image, :string, default: Defaults.Images.aqua_node_collector()
    defaultable_field :trivy_checks_image, :string, default: Defaults.Images.aqua_trivy_checks()
    defaultable_field :version_tag, :string, default: "0.52.0"
  end
end
