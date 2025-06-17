defmodule CommonCore.Batteries.VMAgentConfig do
  @moduledoc false

  use CommonCore, {:embedded_schema, no_encode: [:cookie_secret]}

  alias CommonCore.Defaults

  @read_only_fields ~w(cookie_secret)a

  batt_polymorphic_schema type: :vm_agent do
    defaultable_field :image_tag, :string, default: :vm_agent |> Defaults.Images.get_image!() |> Map.get(:default_tag)

    secret_field :cookie_secret, length: 32, func: &Defaults.urlsafe_random_key_string/1
  end
end
