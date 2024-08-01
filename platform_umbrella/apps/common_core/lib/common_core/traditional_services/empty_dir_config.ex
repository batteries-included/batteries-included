defmodule CommonCore.TraditionalServices.EmptyDirConfig do
  @moduledoc false
  use CommonCore, :embedded_schema

  batt_polymorphic_schema type: :empty_dir do
    field :medium, Ecto.Enum, values: [:default, :memory], default: :default
    field :size_limit, :string
  end
end
