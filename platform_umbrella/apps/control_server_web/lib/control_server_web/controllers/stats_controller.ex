defmodule ControlServerWeb.StatsController do
  use ControlServerWeb, :controller

  require Logger

  action_fallback ControlServerWeb.FallbackController

  def index(conn, _params) do
    state_summary = KubeServices.SystemState.Summarizer.cached()

    dbg(Map.keys(state_summary.kube_state))

    conn
    |> put_status(:ok)
    |> json(%{
      age_seconds: DateTime.diff(DateTime.utc_now(), state_summary.captured_at),
      batteries: Enum.count(state_summary.batteries),
      postgres_clusters: Enum.count(state_summary.postgres_clusters),
      ferret_services: Enum.count(state_summary.ferret_services),
      redis_instances: Enum.count(state_summary.redis_instances),
      notebooks: Enum.count(state_summary.notebooks),
      knative_services: Enum.count(state_summary.knative_services),
      traditional_services: Enum.count(state_summary.traditional_services),
      ip_address_pools: Enum.count(state_summary.ip_address_pools),
      projects: Enum.count(state_summary.projects),
      model_instances: Enum.count(state_summary.model_instances),

      # Stats about what kubestate has
      pods: Enum.count(Map.get(state_summary.kube_state, :pod, [])),
      services: Enum.count(Map.get(state_summary.kube_state, :service, [])),
      deployments: Enum.count(Map.get(state_summary.kube_state, :deployment, [])),
      stateful_sets: Enum.count(Map.get(state_summary.kube_state, :stateful_set, [])),
      nodes: Enum.count(Map.get(state_summary.kube_state, :node, [])),

      # Stats about KeycloakState
      realms: Enum.count(Map.get(state_summary.keycloak_state || %{}, :realms, []))
    })
  end
end
