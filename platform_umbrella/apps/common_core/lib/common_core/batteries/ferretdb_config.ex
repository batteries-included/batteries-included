defmodule CommonCore.Batteries.FerretDBConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Defaults

  batt_polymorphic_schema type: :ferretdb do
    defaultable_field :ferretdb_image, :string, default: Defaults.Images.ferretdb_image()
  end
end
