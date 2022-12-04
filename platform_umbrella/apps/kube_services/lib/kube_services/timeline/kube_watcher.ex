defmodule KubeServices.Timeline.KubeWatcher do
  use GenServer

  import K8s.Resource.FieldAccessors, only: [name: 1, namespace: 1]

  alias ControlServer.Timeline
  alias EventCenter.KubeState
  alias EventCenter.KubeState.Payload

  require Logger

  defmodule State do
    defstruct past_init: false,
              resource_type: :pod
  end

  def start_link(opts) do
    state = struct!(State, opts)
    GenServer.start_link(__MODULE__, state)
  end

  @impl GenServer
  def init(%State{resource_type: type} = state) do
    :ok = KubeState.subscribe(type)
    {:ok, state}
  end

  @impl GenServer
  def handle_info(
        %Payload{action: action} = _msg,
        %State{past_init: false, resource_type: type} = state
      )
      when action not in ["add", :add] do
    new_state = %State{state | past_init: true}

    Logger.info("Seeing first #{action} for type #{type} assuming following events are real",
      type: type,
      state: state,
      new_state: new_state,
      action: action
    )

    {:noreply, new_state}
  end

  @impl GenServer
  def handle_info(
        %Payload{action: action} = _msg,
        %State{past_init: false, resource_type: type} = state
      ) do
    Logger.debug("Skipping #{action} for #{type} before init",
      type: type,
      state: state,
      action: action
    )

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(
        %Payload{action: action, resource: resource} = _msg,
        %State{past_init: true, resource_type: type} = state
      )
      when action in ["add", :add, "delete", :delete] do
    name = name(resource)
    namespace = namespace(resource)

    event = Timeline.kube_event(action, type, name, namespace)
    {:ok, _} = Timeline.create_timeline_event(event)

    Logger.debug("resource logged",
      type: type,
      action: action,
      name: name,
      namespace: namespace
    )

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(%Payload{} = _msg, %State{} = state) do
    {:noreply, state}
  end
end
