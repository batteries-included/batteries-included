defmodule CommonCore.Batteries.NotebooksConfig do
  @moduledoc false

  use CommonCore, {:embedded_schema, no_encode: [:cookie_secret]}

  alias CommonCore.Defaults

  @required_fields ~w()a

  batt_polymorphic_schema type: :notebooks do
    secret_field :cookie_secret, length: 32, func: &Defaults.urlsafe_random_key_string/1
  end
end
