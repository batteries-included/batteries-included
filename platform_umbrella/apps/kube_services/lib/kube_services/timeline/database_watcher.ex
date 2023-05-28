defmodule KubeServices.Timeline.DatabaseWatcher do
  use GenServer
  use TypedStruct

  alias ControlServer.Timeline
  alias EventCenter.Database, as: DatabaseEventCenter

  require Logger

  typedstruct module: State do
    field :source_type, atom(), default: :postgres_cluster
  end

  def start_link(opts) do
    state = struct!(State, opts)
    GenServer.start_link(__MODULE__, state)
  end

  @impl GenServer
  def init(%State{source_type: type} = state) do
    :ok = DatabaseEventCenter.subscribe(type)
    {:ok, state}
  end

  @impl GenServer
  def handle_info({action, object}, %State{source_type: type} = state) do
    {:ok, _} = to_event(type, action, object)
    {:noreply, state}
  end

  defp to_event(type, action, %{name: name} = _object) do
    Logger.debug("Going to persist timeline event for #{type} action #{action}",
      type: type,
      action: action,
      name: name
    )

    event = Timeline.named_database_event(action, type, name)
    Timeline.create_timeline_event(event)
  end
end
