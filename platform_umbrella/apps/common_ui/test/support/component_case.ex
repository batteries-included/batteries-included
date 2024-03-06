defmodule CommonUI.ComponentCase do
  @moduledoc """
  Use with your component tests.
  """

  use ExUnit.CaseTemplate

  setup do
    # This will run before each test that uses this case
    :ok
  end

  using do
    quote do
      import Phoenix.Component
      import Phoenix.LiveViewTest
      import Plug.HTML, only: [html_escape: 1]
    end
  end
end
