defmodule CommonCore.Batteries.OllamaConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  @required_fields ~w()a

  batt_polymorphic_schema type: :ollama do
    defaultable_image_field :image, image_id: :ollama
  end
end
