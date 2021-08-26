defmodule KubeServices.Worker do
  @moduledoc """
  Module to interact with BaseService and Kubernetes resources.
  """
  use GenServer

  alias ControlServer.Services
  alias KubeExt.Hashing
  alias KubeResources.ConfigGenerator

  require Logger

  @tick_time 30_000

  defmodule ApplyState do
    @moduledoc """
    Simple struct to hold information about the last time we
    tried to apply this resource spec to kubernetes.
    """
    defstruct [:resource, :last_result]

    def needs_apply(%ApplyState{} = ap, resource) do
      # If the last try was an error then we always try and sync.
      # otherwise if there's been something that changed in the database.
      !ok?(ap) || different?(ap, resource)
    end

    def apply(connection, resource) do
      %ApplyState{last_result: KubeExt.maybe_apply(connection, resource), resource: resource}
    end

    def from_path(%{} = path_state_map, path), do: Map.get(path_state_map, path, nil)

    def ok?(%ApplyState{last_result: last_result}), do: result_ok?(last_result)

    defp result_ok?(:ok), do: true
    defp result_ok?({:ok, _}), do: true

    defp result_ok?(result) when is_list(result) do
      Enum.all?(result, &result_ok?/1)
    end

    defp result_ok?(_), do: false

    def different?(%ApplyState{resource: applied_resource}, new_resource) do
      Hashing.different?(applied_resource, new_resource)
    end
  end

  defmodule State do
    @doc """
    The state of the current worker. Chaning this state is most of the
    reponsibility of this worker. This comes in two main forms:

    - Refreshing from the database, updating the desired resources.
    - Taking the desired state and applying it to kubernetes recording the result.
    """

    defstruct [:base_service, :requested_resources, :connection, path_state_map: %{}]

    def new(base_service) do
      %__MODULE__{
        base_service: base_service,
        # Compute the initial kube stuff that we want, and assume that none is there.
        requested_resources: ConfigGenerator.materialize(base_service)
      }
    end

    def refresh(%State{base_service: old_bs} = state) do
      # Get the most up to date base service from the db.
      base_service = Services.get_base_service!(old_bs.id)

      %__MODULE__{
        state
        | # Now compute the resources we want and store the new base_service
          base_service: base_service,
          requested_resources: ConfigGenerator.materialize(base_service)
      }
    end

    def connection(%State{}),
      do: KubeExt.ConnectionPool.get(KubeServices.ConnectionPool, :default)

    def apply_resources(%State{} = state) do
      new_path_state_map =
        state.requested_resources
        |> sort_resources()
        |> maybe_apply_all(state)
        |> Map.new()

      Logger.debug("Completed path_state_map with #{map_size(new_path_state_map)} resources")
      %__MODULE__{state | path_state_map: new_path_state_map}
    end

    defp sort_resources(resource_map) do
      Enum.sort(resource_map, fn {a, _av}, {b, _bv} -> a <= b end)
    end

    defp maybe_apply_all(resource_map, state) do
      Enum.map(resource_map, fn {path, resource} ->
        maybe_apply_path(state, path, resource)
      end)
    end

    defp maybe_apply_path(
           %State{path_state_map: path_state_map} = state,
           path,
           resource
         ) do
      # Wild complex with statement.
      #
      # Essentially it assumes that that is no need to push the resource specs.
      # If we do then it's because there's no record of our last sync
      # Or the last sync was a failure
      # or the content hashes that we think are there and
      # want to push have diverged because of changes to the database.
      with {:prev_state, %ApplyState{} = prev_state} <-
             {:prev_state, ApplyState.from_path(path_state_map, path)},
           {:needs_apply, false} <-
             {:needs_apply, ApplyState.needs_apply(prev_state, resource)} do
        Logger.debug("Path => #{path} everything looks the same. Not going to push")
        {path, prev_state}
      else
        {:prev_state, _} ->
          Logger.debug(
            "Appears like we don't know the apply status of #{path} pushing to kubernetes"
          )

          {path, ApplyState.apply(State.connection(state), resource)}

        {:needs_apply, _} ->
          Logger.debug("Last apply state doesn't match for #{path}")
          {path, ApplyState.apply(State.connection(state), resource)}
      end
    end
  end

  def finish(base_service) do
    GenServer.cast(via_tuple(base_service), :finish)
  end

  def start_link(base_service) do
    GenServer.start_link(__MODULE__, base_service, name: via_tuple(base_service))
  end

  def child_spec(base_service) do
    %{
      id: {__MODULE__, base_service.id},
      start: {__MODULE__, :start_link, [base_service]},
      restart: :temporary
    }
  end

  @impl true
  def init(base_service) do
    Logger.debug(
      "KubeServices start worker service_type => #{inspect(base_service.service_type)}"
    )

    state = State.new(base_service)
    Process.send_after(self(), :tick, 1000)

    {:ok, state}
  end

  def via_tuple(base_service) do
    {:via, Registry, {KubeServices.Registry.Worker, base_service.id}}
  end

  @impl true
  def handle_cast(:refresh, %State{} = state) do
    {:noreply, State.refresh(state)}
  end

  @impl true
  def handle_cast(:apply, %State{} = state) do
    {:noreply, State.apply_resources(state)}
  end

  @impl true
  def handle_cast(:finish, %State{} = state) do
    {:stop, :normal, state}
  end

  @impl true
  def handle_info(:tick, %State{} = state) do
    Process.send_after(self(), :tick, @tick_time)
    {:noreply, state |> State.refresh() |> State.apply_resources()}
  end
end
