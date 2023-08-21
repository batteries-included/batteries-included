defmodule KubeServices.SnapshotApply.WorkerKeycloakWrangler do
  @moduledoc false
  use GenServer
  use TypedStruct

  alias EventCenter.Database

  @doc """
  This GenServer will subscribe to the battery events then if
  it sees that any battery changes that will effect *HOW* we
  apply the snapshot then the wrangler takes the correct
  action. Currently SSO status is the only thing.
  """
  @state_opts []
  @me __MODULE__

  typedstruct module: State do
  end

  @spec start_link(keyword) :: {:ok, pid}
  def start_link(opts \\ []) do
    {state_opts, opts} =
      opts
      |> Keyword.put_new(:name, @me)
      |> Keyword.split(@state_opts)

    GenServer.start_link(@me, state_opts, opts)
  end

  @impl GenServer
  def handle_info({:multi, %{installed: bat_map} = _install_result}, state) do
    installed_sso =
      bat_map
      |> Map.values()
      |> Enum.filter(&(&1.type == :sso))
      |> List.first(nil)

    if installed_sso != nil do
      KubeServices.SnapshotApply.Worker.set_keycloak_running(true)
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:delete, deleted_battery}, state) do
    if deleted_battery.type == :sso do
      KubeServices.SnapshotApply.Worker.set_keycloak_running(false)
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(_, state) do
    {:noreply, state}
  end

  @impl GenServer
  def init(opts) do
    # start getting updates about batteries changing.
    :ok = Database.subscribe(:system_battery)

    sso_running = ControlServer.Batteries.battery_enabled?(:sso)
    KubeServices.SnapshotApply.Worker.set_keycloak_running(sso_running)

    {:ok, struct(State, opts)}
  end
end
