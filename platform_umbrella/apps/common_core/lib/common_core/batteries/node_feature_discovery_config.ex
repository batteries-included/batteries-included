defmodule CommonCore.Batteries.NodeFeatureDiscoveryConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  batt_polymorphic_schema type: :node_feature_discovery do
    defaultable_image_field :image, image_id: :node_feature_discovery
  end
end
