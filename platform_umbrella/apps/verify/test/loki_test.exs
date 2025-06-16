defmodule Verify.LokiTest do
  use Verify.TestCase, async: false, batteries: ~w(loki)a, images: ~w(grafana loki)a

  verify "loki is running", %{session: session} do
    assert_pod_running(session, "loki-0")
  end
end
