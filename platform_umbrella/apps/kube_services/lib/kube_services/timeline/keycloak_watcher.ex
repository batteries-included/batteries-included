defmodule KubeServices.Timeline.KeycloakWatcher do
  @moduledoc false
  use GenServer

  alias ControlServer.Timeline
  alias EventCenter.Keycloak, as: KeycloakEventCenter
  alias EventCenter.Keycloak.Payload

  require Logger

  @user_topics ~w(create_user reset_user_password)a

  def start_link(_opts \\ []) do
    state = %{}
    GenServer.start_link(__MODULE__, state)
  end

  @impl GenServer
  def init(state) do
    Enum.each(@user_topics, fn topic ->
      :ok = KeycloakEventCenter.subscribe(topic)
    end)

    {:ok, state}
  end

  @impl GenServer
  def handle_info(%Payload{action: action, resource: %{id: id, realm: realm}}, state) when action in @user_topics do
    {:ok, _event} =
      action
      |> Timeline.keycloak_event(id, realm)
      |> Timeline.create_timeline_event()

    {:noreply, state}
  end

  def handle_info(unknown, state) do
    Logger.warning("Received unexpected message: #{inspect(unknown)}")
    {:noreply, state}
  end
end
