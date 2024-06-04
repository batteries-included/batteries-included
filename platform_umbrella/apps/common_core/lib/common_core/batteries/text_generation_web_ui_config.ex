defmodule CommonCore.Batteries.TextGenerationWebUIConfig do
  @moduledoc false

  use CommonCore, {:embedded_schema, no_encode: [:cookie_secret]}

  alias CommonCore.Defaults

  batt_polymorphic_schema type: :text_generation_webui do
    defaultable_field :image, :string, default: Defaults.Images.text_generation_webui_image()
    secret_field :cookie_secret, length: 32, func: &Defaults.urlsafe_random_key_string/1
  end
end
