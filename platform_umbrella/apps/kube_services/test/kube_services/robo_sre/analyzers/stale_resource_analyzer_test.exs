defmodule KubeServices.RoboSRE.Analyzers.StaleResourceAnalyzerTest do
  use ExUnit.Case

  import Mox

  setup :verify_on_exit!

  test "StaleResourceAnalyzer loads successfully" do
    assert Code.ensure_loaded?(KubeServices.RoboSRE.Analyzers.StaleResourceAnalyzer)
  end
end
