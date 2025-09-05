defmodule KubeServices.RoboSRE.Handlers.StaleResourceHandlerTest do
  use ExUnit.Case

  import Mox

  setup :verify_on_exit!

  test "StaleResourceHandler loads successfully" do
    assert Code.ensure_loaded?(KubeServices.RoboSRE.Handlers.StaleResourceHandler)
  end
end
