defmodule CommonCore.Batteries.CatalogGroup do
  @moduledoc false
  use TypedStruct

  typedstruct do
    field :type, atom(), enforce: true
    field :name, String.t(), enforce: true
    field :icon, atom(), enforce: true
    field :path, String.t(), enforce: true
    field :show_for_nav, boolean()
    field :show_for_projects, boolean()
  end
end
