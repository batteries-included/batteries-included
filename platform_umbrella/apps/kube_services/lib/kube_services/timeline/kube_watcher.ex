defmodule KubeServices.Timeline.KubeWatcher do
  use GenServer
  use TypedStruct

  import K8s.Resource.FieldAccessors, only: [name: 1, namespace: 1]

  alias ControlServer.Timeline
  alias EventCenter.KubeState
  alias EventCenter.KubeState.Payload
  alias KubeServices.Timeline.PodStatus

  require Logger

  typedstruct module: State do
    field :resource_type, atom(), default: :pod
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
        %Payload{action: action, resource: resource} = _msg,
        %State{resource_type: type} = state
      )
      when type in ["pod", :pod] do
    case action do
      :delete ->
        create_event(action, type, resource)
        PodStatus.delete(resource)

      :add ->
        create_event(action, type, resource)
        PodStatus.upsert(resource)

      :update ->
        status_table = KubeServices.Timeline.Kube.pod_status_table()

        case PodStatus.status_changed?(status_table, resource) do
          # status changed to ready
          {true, :ready = status} ->
            create_event(action, type, resource, status)
            PodStatus.upsert(resource)

          # status changed but not to ready
          {true, _} ->
            PodStatus.upsert(resource)

          # status hasn't changed - no need to update anything
          _ ->
            nil
        end
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(
        %Payload{action: action, resource: resource} = _msg,
        %State{resource_type: type} = state
      )
      when action in ["add", :add, "delete", :delete] do
    create_event(action, type, resource)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(%Payload{} = _msg, %State{} = state) do
    {:noreply, state}
  end

  defp create_event(action, type, resource, status \\ nil) do
    name = name(resource)
    namespace = namespace(resource)
    event = Timeline.kube_event(action, type, name, namespace, status)
    {:ok, _} = Timeline.create_timeline_event(event)

    Logger.debug("resource logged",
      type: type,
      action: action,
      name: name,
      namespace: namespace
    )
  end
end
