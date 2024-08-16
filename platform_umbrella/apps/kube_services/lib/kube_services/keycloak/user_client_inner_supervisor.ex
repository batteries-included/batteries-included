defmodule KubeServices.Keycloak.UserClientInnerSupervisor do
  @moduledoc false
  use Supervisor

  alias CommonCore.StateSummary.KeycloakSummary
  alias KubeServices.Keycloak.UserClient
  alias KubeServices.SystemState.Summarizer

  require Logger

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  def init(opts) do
    # Get the most recent version of the state summary
    summary = Keyword.get_lazy(opts, :state_summary, &Summarizer.cached/0)
    client = KeycloakSummary.client(summary.keycloak_state, "battery_core")
    url = summary |> CommonCore.StateSummary.URLs.uri_for_battery(:battery_core) |> URI.to_string()
    children = children(client, url)

    Logger.info("Starting Keycloak user client supervisor with length = #{length(children)}")

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp children(%{realm: realm, client: %{clientId: client_id, secret: secret}}, url) do
    [{UserClient, [realm: realm, client_id: client_id, client_secret: secret, battery_core_url: url]}]
  end

  defp children(_, _), do: []
end
