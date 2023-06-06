defmodule KubeServices.Batteries.InstalledWatcher do
  @moduledoc """
  This genserver is responsible for lifecycle of battery supervision trees.

  AKA

  It starts things when a new battery type is installed.
  It stops things when a battery type is removed.
  """
  use GenServer

  alias EventCenter.Database

  require Logger

  @dynamic_supervisor KubeServices.Batteries.DynamicSupervisor
  @registry KubeServices.Batteries.Registry
  def start_link(opts \\ []) do
    # you may want to register your server with `name: __MODULE__`
    # as a third argument to `start_link`
    GenServer.start_link(__MODULE__, opts)
  end

  def init(_args) do
    :ok = Database.subscribe(:system_battery)
    Enum.each(ControlServer.Batteries.list_system_batteries(), &start_battery/1)
    {:ok, :initial_state}
  end

  def handle_info({:multi, %{installed: bat_map} = _install_result}, state) do
    Enum.each(bat_map, fn {_type, system_battery} ->
      start_battery(system_battery)
    end)

    {:noreply, state}
  end

  def handle_info({:delete, deleted_battery}, state) do
    Logger.debug("Got delete message, #{inspect(deleted_battery)}")
    :ok = stop_battery(deleted_battery)
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defp start_battery(%{} = battery) do
    {:ok, _child} =
      battery
      |> process_type()
      |> start_process()
  end

  defp stop_battery(%{id: id} = _battery) do
    case Registry.lookup(@registry, id) do
      [{pid, _}] ->
        Logger.debug("Stopping battery pid #{inspect(pid)}")
        DynamicSupervisor.terminate_child(@dynamic_supervisor, pid)

      [] ->
        :ok
    end
  end

  # For each battery type that needs some process tree (one genserver, to a whole process tree, etc)
  # needs to implement this function. Specifying the base module to use when determing the
  # `child_spec` to run
  defp process_type(%{type: :sso} = battery), do: {KubeServices.Batteries.SSO, battery}

  defp process_type(%{type: :battery_core} = battery),
    do: {KubeServices.Batteries.BatteryCore, battery}

  defp process_type(%{} = battery), do: {nil, battery}

  defp start_process({nil = _process_module, _battery}), do: {:ok, nil}

  defp start_process({process_module, battery}) do
    Logger.info("New batery #{battery.id} with proccess #{process_module} tree to install.")

    DynamicSupervisor.start_child(@dynamic_supervisor, {process_module, [battery: battery]})
  end
end
