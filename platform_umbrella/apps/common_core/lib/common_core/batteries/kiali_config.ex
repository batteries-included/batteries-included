defmodule CommonCore.Batteries.KialiConfig do
  @moduledoc false

  use CommonCore, {:embedded_schema, no_encode: [:login_signing_key]}

  alias CommonCore.Batteries.KialiConfig

  @required_fields ~w()a

  batt_polymorphic_schema type: :kiali do
    defaultable_image_field :image, image_id: :kiali

    secret_field :login_signing_key, length: 32
  end

  @spec image_version(t()) :: String.t()
  def image_version(%KialiConfig{image: image} = _config) do
    image
    |> String.split(":")
    |> List.last()
  end
end
