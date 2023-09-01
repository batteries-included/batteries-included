defmodule ControlServerWeb.IntegrationTestCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  using do
    quote do
      use ExUnit.Case, async: false
      use Wallaby.Feature

      import Wallaby.Query
    end
  end
end
