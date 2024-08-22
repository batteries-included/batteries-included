defmodule CommonCore.Defaults.Image do
  @moduledoc false
  use TypedStruct

  typedstruct do
    field :base, String.t(), enforce: true
    field :versions, [String.t()], enforce: true
  end
end
