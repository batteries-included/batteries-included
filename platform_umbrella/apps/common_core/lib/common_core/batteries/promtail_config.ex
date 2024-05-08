defmodule CommonCore.Batteries.PromtailConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Defaults

  batt_polymorphic_schema type: :promtail do
    defaultable_field :image, :string, default: Defaults.Images.promtail_image()
  end
end
