defmodule KubeServices.RoboSRE.DeleteResourceExecutor do
  @moduledoc false
  @behaviour KubeServices.RoboSRE.Executor

  use GenServer
  use TypedStruct

  alias CommonCore.RoboSRE.Action
  alias KubeServices.KubeState
  alias KubeServices.ResourceDeleter

  require Logger

  @state_opts [:resource_deleter, :kube_state]
  @me __MODULE__

  typedstruct module: State do
    field :resource_deleter, module(), default: ResourceDeleter
    field :kube_state, module(), default: KubeState
  end

  def start_link(opts \\ []) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    {init_opts, opts} = Keyword.split(opts, @state_opts)

    GenServer.start_link(__MODULE__, init_opts, opts)
  end

  @impl GenServer
  def init(opts) do
    resource_deleter = Keyword.get(opts, :resource_deleter, ResourceDeleter)
    kube_state = Keyword.get(opts, :kube_state, KubeState)

    state = %State{resource_deleter: resource_deleter, kube_state: kube_state}

    {:ok, state}
  end

  @impl KubeServices.RoboSRE.Executor
  @spec execute(Action.t()) :: {:ok, any()} | {:error, any()}
  def execute(%Action{action_type: :delete_resource} = action) do
    GenServer.call(@me, {:execute, action})
  end

  def execute(%Action{action_type: other}) do
    {:error, {:unsupported_action_type, other}}
  end

  @impl GenServer
  def handle_call(
        {:execute, %Action{action_type: :delete_resource, params: params}},
        _from,
        %State{resource_deleter: resource_deleter, kube_state: kube_state} = state
      ) do
    api_version_kind =
      params
      |> Map.get(:api_version_kind, Map.get(params, "api_version_kind", nil))
      |> to_atom()

    namespace = Map.get(params, :namespace, Map.get(params, "namespace", nil))
    name = Map.get(params, :name, Map.get(params, "name", nil))

    with {:ok, resource} <- kube_state.get(api_version_kind, namespace, name),
         {:ok, result} <- resource_deleter.delete(resource) do
      {:reply, {:ok, result}, state}
    else
      :missing ->
        Logger.warning(
          "Resource to delete not found (api_version_kind: #{inspect(api_version_kind)}, namespace: #{inspect(namespace)}, name: #{inspect(name)})"
        )

        {:reply, {:ok, :not_found}, state}

      {:error, :not_found} ->
        Logger.warning(
          "Resource to delete not found (api_version_kind: #{inspect(api_version_kind)}, namespace: #{inspect(namespace)}, name: #{inspect(name)})"
        )

        {:reply, {:ok, :not_found}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  defp to_atom(string) when is_binary(string) do
    String.to_atom(string)
  end

  defp to_atom(atom) when is_atom(atom), do: atom
end
