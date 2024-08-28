defmodule CommonCore.Defaults.Image do
  @moduledoc false
  use TypedStruct

  typedstruct enforce: true do
    field :name, String.t()
    field :tags, [String.t()]
    field :default_tag, String.t()
  end
end
