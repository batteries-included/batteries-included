defmodule CommonCore.Batteries.TrivyOperatorConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Defaults

  batt_polymorphic_schema type: :trivy_operator do
    defaultable_field :image, :string, default: Defaults.Images.trivy_operator_image()
    defaultable_field :version_tag, :string, default: "0.42.0"
  end
end
