defmodule Verify.PromtailTest do
  use Verify.TestCase,
    async: false,
    batteries: ~w(promtail)a,
    images: ~w(grafana loki promtail)a

  verify "promtail is running", %{session: session} do
    assert_pod_running(session, "promtail-")

    # TODO: assert logs being shipped to loki
  end
end
