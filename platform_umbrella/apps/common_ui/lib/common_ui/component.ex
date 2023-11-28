defmodule CommonUI.Component do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      use Phoenix.Component, global_prefixes: ~w(x- phx- aria- data-)

      import CommonUI.Link
      import Phoenix.Component, except: [link: 1]
    end
  end
end
