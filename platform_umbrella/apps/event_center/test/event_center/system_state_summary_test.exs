defmodule EventCenter.SystemStateSummaryTest do
  use ExUnit.Case

  test "publishes event to subscribers" do
    payload = %{
      batteries: [],
      postgres_clusters: [],
      redis_clusters: [],
      ferret_services: [],
      backend_services: [],
      notebooks: [],
      knative_services: [],
      ip_address_pools: [],
      projects: [],
      keycloak_state: nil,
      kube_state: %{}
    }

    EventCenter.SystemStateSummary.subscribe()
    EventCenter.SystemStateSummary.broadcast(payload)
    assert_receive ^payload
  end
end
