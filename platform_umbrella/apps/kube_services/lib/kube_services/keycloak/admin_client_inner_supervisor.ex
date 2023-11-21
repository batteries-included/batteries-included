defmodule KubeServices.Keycloak.AdminClientInnerSupervisor do
  @moduledoc false
  use Supervisor

  alias CommonCore.Keycloak.AdminClient
  alias CommonCore.StateSummary.Creds
  alias CommonCore.StateSummary.Hosts
  alias KubeServices.SystemState.Summarizer

  require Logger

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  def init(_opts) do
    # Get the most recent version of the state summary
    summary = Summarizer.cached()
    base_url = "http://" <> Hosts.keycloak_host(summary)
    username = Creds.root_keycloak_username(summary)
    password = Creds.root_keycloak_password(summary)

    Logger.info("Starting Keycloak admin client with base_url = #{base_url} and username = #{username}")

    children = [
      # Start the AdminClient with the latest credentials and base_url
      {AdminClient, [base_url: base_url, username: username, password: password]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
