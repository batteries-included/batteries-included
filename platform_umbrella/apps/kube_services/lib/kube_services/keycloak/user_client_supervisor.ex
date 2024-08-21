defmodule KubeServices.Keycloak.UserClientSupervisor do
  @moduledoc false
  use Supervisor

  alias CommonCore.StateSummary

  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init(_opts) do
    children = [
      {KubeServices.SystemState.ReconfigCanary, [methods: [&get_client/1]]},
      KubeServices.Keycloak.UserClientInnerSupervisor
    ]

    Logger.info("Starting UserClientSupervisor")

    Supervisor.init(children, strategy: :one_for_all)
  end

  defp get_client(nil), do: nil

  defp get_client(%StateSummary{} = summary) do
    if summary.keycloak_state == nil do
      Logger.warning("No keycloak state found, cannot get user oauth2 client self = #{inspect(self())}")
      nil
    else
      client = CommonCore.StateSummary.KeycloakSummary.client(summary.keycloak_state, "battery_core")
      client
    end
  end
end
