defmodule ControlServerWeb.Integration.KubeState do
  @moduledoc false
  use ControlServerWeb.IntegrationTestCase

  alias KubeServices.KubeState

  feature "Can show kube nodes state", %{session: session} do
    # Make sure that there are at least this many nodes in the table
    count = length(KubeState.get_all(:node))

    session
    |> visit("/kube/nodes")
    |> assert_has(css("table tbody tr", minimum: count))
  end

  feature "Can show kube pods state", %{session: session} do
    count = length(KubeState.get_all(:pod))

    session
    |> visit("/kube/pods")
    |> assert_has(css("table tbody tr", minimum: count))
  end
end
