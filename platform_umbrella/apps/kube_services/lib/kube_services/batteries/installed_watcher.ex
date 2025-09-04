defmodule KubeServices.Batteries.InstalledWatcher do
  @moduledoc """
  This genserver is responsible for lifecycle of battery supervision trees.

  AKA

  It starts things when a new battery type is installed.
  It stops things when a battery type is removed.
  """
  use GenServer

  alias CommonCore.Batteries.SystemBattery
  alias EventCenter.Database

  require Logger

  @default_battery_type_mapping [
    sso: KubeServices.Batteries.SSO,
    keycloak: KubeServices.Batteries.Keycloak,
    battery_core: KubeServices.Batteries.BatteryCore,
    timeline: KubeServices.Batteries.Timeline,
    stale_resource_cleaner: KubeServices.Batteries.StaleResourceCleaner,
    robo_sre: KubeServices.Batteries.RoboSRE
  ]

  @dynamic_supervisor KubeServices.Batteries.DynamicSupervisor
  @registry KubeServices.Batteries.Registry
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl GenServer
  def init(_args) do
    :ok = Database.subscribe(:system_battery)

    Logger.debug("Started watching for new batteries. Making sure already installed are running")

    # This is super important
    #
    # The battery_core battery is used by lots of batteries
    # It's critical to start it first
    #
    batteries = Enum.sort(ControlServer.Batteries.list_system_batteries(), fn a, _b -> a.type == :battery_core end)

    _ = start_batteries(batteries)
    {:ok, :initial_state}
  end

  @impl GenServer
  # handle starting multiple installed system batteries from database subscription
  def handle_info({:multi, %{installed: bat_map} = _install_result}, state) do
    batteries = Enum.map(bat_map, fn {_type, battery} -> battery end)
    _ = start_batteries(batteries)
    {:noreply, state}
  end

  @impl GenServer
  # handle a deleted battery
  def handle_info({:delete, deleted_battery}, state) do
    Logger.debug("Got delete message, #{inspect(deleted_battery)}")
    :ok = stop_battery(deleted_battery)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  @spec start_batteries([SystemBattery.t()]) :: [
          DynamicSupervisor.on_start_child()
        ]
  defp start_batteries(batteries) do
    Enum.map(batteries, &start_battery/1)
  end

  @spec start_battery(SystemBattery.t()) ::
          DynamicSupervisor.on_start_child()
  defp start_battery(%{type: type} = battery) do
    mod = Keyword.get(@default_battery_type_mapping, type)

    case mod do
      nil ->
        Logger.debug("Not starting anything for battery #{battery.id} with type #{type}")
        :ignore

      _ ->
        Logger.info("New battery #{battery.id} with process #{mod} tree to install.")
        DynamicSupervisor.start_child(@dynamic_supervisor, {mod, [battery: battery]})
    end
  end

  @spec stop_battery(SystemBattery.t()) :: :ok | {:error, :not_found}
  defp stop_battery(%{id: id} = _battery) do
    case Registry.lookup(@registry, id) do
      [{pid, _}] ->
        Logger.debug("Stopping battery pid #{inspect(pid)}")
        DynamicSupervisor.terminate_child(@dynamic_supervisor, pid)

      [] ->
        :ok
    end
  end
end
