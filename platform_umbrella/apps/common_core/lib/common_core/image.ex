defmodule CommonCore.Image do
  @moduledoc false
  use CommonCore, :embedded_schema

  @required_fields ~w(image versions default)a

  batt_embedded_schema do
    field :image, :string
    field :versions, {:array, :string}
    field :default, :string
  end
end
