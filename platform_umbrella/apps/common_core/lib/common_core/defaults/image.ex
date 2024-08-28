defmodule CommonCore.Defaults.Image do
  @moduledoc false
  use CommonCore, :embedded_schema

  batt_embedded_schema do
    field :name, :string
    field :tags, {:array, :string}
    field :default_tag, :string
  end
end
