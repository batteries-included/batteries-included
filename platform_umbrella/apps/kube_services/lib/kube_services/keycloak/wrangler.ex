defmodule KubeServices.Keycloak.Wrangler do
  @moduledoc """
  ???
  """
  use GenServer
  use TypedStruct

  alias CommonCore.Keycloak.AdminClient
  alias KubeServices.SystemState.SummaryHosts
  alias CommonCore.StateSummary.Hosts
  alias CommonCore.StateSummary.Creds

  typedstruct module: State do
    field :client_pid, pid()
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [opts])
  end

  @impl GenServer
  def init(_args) do
    :ok = EventCenter.SystemStateSummary.subscribe()

    {:ok, pid} =
      AdminClient.start_link(
        username: "batteryadmin",
        password: "testing",
        base_url: "http://" <> SummaryHosts.keycloak_host()
      )

    {:ok, %State{client_pid: pid}}
  end

  @impl GenServer
  def handle_info(
        %CommonCore.StateSummary{} = summary,
        %State{client_pid: pid} = state
      ) do
    new_host = Hosts.keycloak_host(summary)
    new_base_url = "http://" <> new_host
    new_username = Creds.root_keycloak_user(summary)
    new_password = Creds.root_keycloak_password(summary)

    AdminClient.reset(pid, new_base_url, new_username, new_password)

    {:noreply, state}
  end
end
