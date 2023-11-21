defmodule KubeServices.Keycloak.OIDCInnerSupervisor do
  @moduledoc false
  use Supervisor

  alias CommonCore.StateSummary.Hosts
  alias KubeServices.SystemState.Summarizer

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init(_opts) do
    summary = Summarizer.cached()
    Supervisor.init(children(summary), strategy: :one_for_one)
  end

  # It's important that we don't start the provider early or it will flap
  # so make sure that there are realms before starting the provider
  defp children(%{keycloak_state: %{realms: realms}} = summary) when realms != [] do
    url = "http://" <> Hosts.keycloak_host(summary) <> "/realms/batterycore"

    [
      {Oidcc.ProviderConfiguration.Worker,
       %{
         issuer: url,
         name: KubeServices.Keycloak.OIDCProvider,
         provider_configuration_opts: %{quirks: %{allow_unsafe_http: true}}
       }}
    ]
  end

  defp children(_), do: []
end
