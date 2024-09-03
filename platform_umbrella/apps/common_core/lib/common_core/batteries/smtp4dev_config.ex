defmodule CommonCore.Batteries.Smtp4devConfig do
  @moduledoc false

  use CommonCore, {:embedded_schema, no_encode: [:cookie_secret]}

  alias CommonCore.Defaults

  @required_fields ~w()a

  batt_polymorphic_schema type: :smtp4dev do
    defaultable_image_field :image, image_id: :smtp4dev

    secret_field :cookie_secret, length: 32, func: &Defaults.urlsafe_random_key_string/1
  end
end
