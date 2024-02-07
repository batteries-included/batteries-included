defmodule KubeServices.Keycloak.OIDCSupervisor do
  @moduledoc false

  use Supervisor

  alias CommonCore.StateSummary.URLs

  require Logger

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init(_opts) do
    children = [
      {KubeServices.SystemState.ReconfigCanary, [methods: [&battery_core_present?/1, &keycloak_base_url/1]]},
      KubeServices.Keycloak.OIDCInnerSupervisor
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  @spec battery_core_present?(any()) :: boolean()
  def battery_core_present?(%{keycloak_state: %{realms: realms}} = _summary) do
    Enum.any?(realms, &(&1.realm == "batterycore"))
  end

  def battery_core_present?(_summary), do: false

  def keycloak_base_url(state) do
    state |> URLs.uri_for_battery(:keycloak) |> URI.to_string()
  end
end
