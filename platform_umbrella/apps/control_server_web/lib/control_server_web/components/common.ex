defmodule ControlServerWeb.Common do
  @moduledoc """
  Import common components for use in ControlServerWeb only
  """

  defmacro __using__(_) do
    quote do
      import ControlServerWeb.Common.Page
    end
  end
end
