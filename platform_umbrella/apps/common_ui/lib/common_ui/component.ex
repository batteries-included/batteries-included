defmodule CommonUI.Component do
  defmacro __using__(_opts) do
    quote do
      use Phoenix.Component
      import Phoenix.Component, except: [link: 1]

      import CommonUI.Link
      import CommonUI.CSSHelpers
    end
  end
end
