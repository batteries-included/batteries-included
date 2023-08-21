defmodule CommonUI.Component do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      use Phoenix.Component

      import CommonUI.CSSHelpers
      import CommonUI.Link
      import Phoenix.Component, except: [link: 1]
    end
  end
end
