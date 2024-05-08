defmodule CommonCore.Batteries.KialiConfig do
  @moduledoc false

  use CommonCore, {:embedded_schema, no_encode: [:login_signing_key]}

  alias CommonCore.Defaults

  @required_fields ~w()a

  batt_polymorphic_schema type: :kiali do
    defaultable_field :image, :string, default: Defaults.Images.kiali_image()
    defaultable_field :version, :string, default: Defaults.Monitoring.kiali_version()

    secret_field :login_signing_key, length: 32
  end
end
