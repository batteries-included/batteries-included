defmodule KubeServices.SystemState.SummaryRecent do
  @moduledoc false
  use GenServer
  use TypedStruct

  alias CommonCore.StateSummary
  alias EventCenter.SystemStateSummary
  alias KubeServices.SystemState.Summarizer

  require Logger

  typedstruct module: State do
    # This is the last summary we received
    field :summary, StateSummary.t(), default: nil, enforce: false

    # Does the GenServer subscribe to the SystemStateSummary updates
    field :subscribe, boolean(), default: true, enforce: false
  end

  @me __MODULE__
  def start_link(opts) do
    {state_opts, genserver_opts} = opts |> Keyword.put_new(:name, @me) |> Keyword.split([:summary])
    GenServer.start_link(@me, state_opts, genserver_opts)
  end

  @impl GenServer
  def init(opts) do
    Logger.debug("Starting SummaryRecent")

    opts = Keyword.put_new_lazy(opts, :summary, &Summarizer.cached/0)
    state = struct(State, opts)

    if state.subscribe do
      :ok = SystemStateSummary.subscribe()
    end

    {:ok, state}
  end

  @impl GenServer
  def handle_info(%StateSummary{} = message, state) do
    new_state = %{state | summary: message}
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_call({_, _}, _from, %{summary: nil} = state) do
    {:reply, [], state}
  end

  def handle_call({:keycloak_realms, limit}, _from, %{summary: summary} = state) when summary != nil do
    list =
      summary
      |> Map.get(:keycloak_state, %{})
      |> Kernel.||(%{})
      |> Map.get(:realms, []) || []

    {:reply, Enum.take(list, limit), state}
  end

  def handle_call({key, limit}, _from, %{summary: summary} = state) when summary != nil do
    # Get the list of items from the summary
    list = Map.get(summary, key, []) || []
    {:reply, sorted_limit(list, limit), state}
  end

  @impl GenServer
  def handle_call({_key, _limit}, _from, state) do
    {:reply, [], state}
  end

  defp sorted_limit(enum, limit) when is_list(enum) do
    enum
    |> Enum.sort_by(& &1.updated_at, {:desc, DateTime})
    |> Enum.take(limit)
  end

  defp sorted_limit(_enum, _limit), do: []

  @spec postgres_clusters(GenServer.server(), integer()) :: list(CommonCore.Postgres.Cluster.t())
  def postgres_clusters(target \\ @me, limit \\ 7) do
    GenServer.call(target, {:postgres_clusters, limit})
  end

  @spec redis_instances(GenServer.server(), integer()) :: list(CommonCore.Redis.RedisInstance.t())
  def redis_instances(target \\ @me, limit \\ 7) do
    GenServer.call(target, {:redis_instances, limit})
  end

  @spec knative_services(GenServer.server(), integer()) :: list(CommonCore.Knative.Service.t())
  def knative_services(target \\ @me, limit \\ 7) do
    GenServer.call(target, {:knative_services, limit})
  end

  @spec keycloak_realms(GenServer.server(), integer()) ::
          list(CommonCore.OpenAPI.KeycloakAdminSchema.RealmRepresentation.t())
  def keycloak_realms(target \\ @me, limit \\ 7) do
    GenServer.call(target, {:keycloak_realms, limit})
  end

  @spec aqua_vulnerability_reports(GenServer.server(), integer()) :: list(map())
  def aqua_vulnerability_reports(target \\ @me, limit \\ 7) do
    GenServer.call(target, {:aqua_vulnerability_reports, limit})
  end

  @spec ip_address_pools(GenServer.server(), integer()) :: list(CommonCore.MetalLB.IPAddressPool.t())
  def ip_address_pools(target \\ @me, limit \\ 7) do
    GenServer.call(target, {:ip_address_pools, limit})
  end

  @spec notebooks(GenServer.server(), integer()) :: list(CommonCore.Notebooks.JupyterLabNotebook.t())
  def notebooks(target \\ @me, limit \\ 7) do
    GenServer.call(target, {:notebooks, limit})
  end

  def model_instances(target \\ @me, limit \\ 7) do
    GenServer.call(target, {:model_instances, limit})
  end

  @spec ferret_services(GenServer.server(), integer()) :: list(CommonCore.FerretDB.FerretService.t())
  def ferret_services(target \\ @me, limit \\ 7) do
    GenServer.call(target, {:ferret_services, limit})
  end

  @spec projects(GenServer.server(), integer()) :: list(CommonCore.Projects.Project.t())
  def projects(target \\ @me, limit \\ 7) do
    GenServer.call(target, {:projects, limit})
  end

  @spec traditional_services(GenServer.server(), integer()) :: list(CommonCore.TraditionalServices.Service.t())
  def traditional_services(target \\ @me, limit \\ 7) do
    GenServer.call(target, {:traditional_services, limit})
  end
end
