defmodule ControlServerWeb.Integration.KubeState do
  use ControlServerWeb.IntegrationTestCase

  alias KubeExt.KubeState

  feature "Can show kube nodes state", %{session: session} do
    # Make sure that there are at least this many nodes in the table
    count = length(KubeState.nodes())

    session
    |> visit("/internal/nodes")
    |> assert_has(css("table tbody tr", minimum: count))
  end

  feature "Can show kube pods state", %{session: session} do
    count = length(KubeState.pods())

    session
    |> visit("/internal/pods")
    |> assert_has(css("table tbody tr", minimum: count))
  end
end
