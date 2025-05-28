defmodule KubeServices.Timeline.BatteryWatcher do
  @moduledoc false
  use GenServer

  alias ControlServer.Timeline
  alias EventCenter.Database, as: DatabaseEventCenter

  require Logger

  def start_link(_opts \\ []) do
    state = %{}
    GenServer.start_link(__MODULE__, state)
  end

  @impl GenServer
  def init(state) do
    :ok = DatabaseEventCenter.subscribe(:system_battery)
    {:ok, state}
  end

  @impl GenServer
  def handle_info({action, object}, state) do
    {:ok, _} = to_event(action, object)
    {:noreply, state}
  end

  defp to_event(:multi, %{installed: installed}) do
    Logger.warning("Going to persist timeline event for battery install event")

    events =
      installed
      |> Map.keys()
      |> Enum.map(fn type ->
        {:ok, event} =
          type
          |> Timeline.battery_install_event()
          |> Timeline.create_timeline_event()

        event
      end)

    {:ok, events}
  end

  defp to_event(action, object) do
    Logger.warning("Not Going to persist timeline event for battery action #{action}",
      action: action,
      id: Map.get(object, :id, nil)
    )

    {:ok, nil}
  end
end
