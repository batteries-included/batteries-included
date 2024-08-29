defmodule CommonCore.Batteries.FerretDBConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  batt_polymorphic_schema type: :ferretdb do
    defaultable_image_field :ferretdb_image, image_id: :ferretdb
  end
end
