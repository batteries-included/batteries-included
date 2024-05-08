defmodule CommonCore.Batteries.VMAgentConfig do
  @moduledoc false

  use CommonCore, {:embedded_schema, no_encode: [:cookie_secret]}

  alias CommonCore.Defaults

  batt_polymorphic_schema type: :vm_agent do
    defaultable_field :image_tag, :string, default: Defaults.Images.vm_tag()
    secret_field :cookie_secret
  end
end
