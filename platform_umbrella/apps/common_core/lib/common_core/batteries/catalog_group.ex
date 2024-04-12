defmodule CommonCore.Batteries.CatalogGroup do
  @moduledoc false
  use TypedStruct

  typedstruct do
    field :id, atom(), enforce: true
    field :name, String.t(), enforce: true
    field :show_for_projects, boolean()
  end
end
