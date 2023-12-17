defmodule KubeServices.SystemState.SummaryRecent do
  @moduledoc false
  use GenServer
  use TypedStruct

  import CommonCore.Resources.FieldAccessors

  alias CommonCore.StateSummary
  alias EventCenter.SystemStateSummary
  alias KubeServices.SystemState.Summarizer

  require Logger

  typedstruct module: State do
    field :summary, StateSummary.t(), default: nil, enforce: false
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
  def handle_call(
        {:postgres_clusters, limit},
        _from,
        %{summary: %StateSummary{postgres_clusters: postgres_clusters}} = state
      )
      when is_list(postgres_clusters) do
    {:reply, sorted_limit(postgres_clusters, limit), state}
  end

  @impl GenServer
  def handle_call({:postgres_clusters, _}, _from, state) do
    {:reply, [], state}
  end

  @impl GenServer
  def handle_call({:redis_clusters, limit}, _from, %{summary: %{redis_clusters: redis_clusters}} = state)
      when is_list(redis_clusters) do
    {:reply, sorted_limit(redis_clusters, limit), state}
  end

  @impl GenServer
  def handle_call({:redis_clusters, _limit}, _from, state) do
    {:reply, [], state}
  end

  @impl GenServer
  def handle_call({:keycloak_realms, limit}, _from, %{summary: %{keycloak_state: %{realms: realms}}} = state)
      when is_list(realms) do
    sorted_realms =
      realms
      |> Enum.sort_by(& &1.realm)
      |> Enum.take(limit)

    {:reply, sorted_realms, state}
  end

  @impl GenServer
  def handle_call({:keycloak_realms, _limit}, _from, state) do
    {:reply, [], state}
  end

  @doc """
  Handles the `:aqua_vulnerability_reports` call by sorting the reports by creation timestamp
  descending, taking the `limit` number of reports, and replying with the limited reports list.
  """
  @impl GenServer
  def handle_call(
        {:aqua_vulnerability_reports, limit},
        _from,
        %{summary: %StateSummary{kube_state: %{aqua_vulnerability_report: reports}}} = state
      )
      when is_list(reports) do
    {:reply,
     reports
     |> Enum.sort_by(fn m -> m |> creation_timestamp() |> Timex.parse!("{ISO:Extended:Z}") end, {:desc, DateTime})
     |> Enum.take(limit), state}
  end

  @impl GenServer
  def handle_call({:aqua_vulnerability_reports, _limit}, _from, state) do
    {:reply, [], state}
  end

  @impl GenServer
  def handle_call({:ip_address_pools, limit}, _from, %{summary: %{ip_address_pools: ip_address_pools}} = state)
      when is_list(ip_address_pools) do
    {:reply, sorted_limit(ip_address_pools, limit), state}
  end

  @impl GenServer
  def handle_call({:ip_address_pools, _limit}, _from, state) do
    {:reply, [], state}
  end

  @impl GenServer
  def handle_call({:knative_services, limit}, _from, %{summary: %{knative_services: knative_services}} = state)
      when is_list(knative_services) do
    {:reply, sorted_limit(knative_services, limit), state}
  end

  @impl GenServer
  def handle_call({:knative_services, _limit}, _from, state) do
    {:reply, [], state}
  end

  @impl GenServer
  def handle_call({:notebooks, limit}, _from, %{summary: %{notebooks: notebooks}} = state) when is_list(notebooks) do
    {:reply, sorted_limit(notebooks, limit), state}
  end

  @impl GenServer
  def handle_call({:notebooks, _limit}, _from, state) do
    {:reply, [], state}
  end

  @impl GenServer
  def handle_call({:ferret_services, limit}, _from, %{summary: %{ferret_services: ferret_services}} = state)
      when is_list(ferret_services) do
    {:reply, sorted_limit(ferret_services, limit), state}
  end

  @impl GenServer
  def handle_call({:ferret_services, _limit}, _from, state) do
    {:reply, [], state}
  end

  defp sorted_limit(enum, limit) do
    enum
    |> Enum.sort_by(& &1.updated_at, {:desc, DateTime})
    |> Enum.take(limit)
  end

  @spec postgres_clusters(atom() | pid() | {atom(), any()} | {:via, atom(), any()}, integer()) ::
          list(CommonCore.Postgres.Cluster.t())
  def postgres_clusters(target \\ @me, limit \\ 7) do
    GenServer.call(target, {:postgres_clusters, limit})
  end

  @spec redis_clusters(atom() | pid() | {atom(), any()} | {:via, atom(), any()}, integer()) ::
          list(CommonCore.Redis.FailoverCluster.t())
  def redis_clusters(target \\ @me, limit \\ 7) do
    GenServer.call(target, {:redis_clusters, limit})
  end

  @spec knative_services(atom() | pid() | {atom(), any()} | {:via, atom(), any()}, integer()) ::
          list(CommonCore.Knative.Service.t())
  def knative_services(target \\ @me, limit \\ 7) do
    GenServer.call(target, {:knative_services, limit})
  end

  @spec keycloak_realms(atom() | pid() | {atom(), any()} | {:via, atom(), any()}, integer()) ::
          list(CommonCore.OpenApi.KeycloakAdminSchema.RealmRepresentation.t())
  def keycloak_realms(target \\ @me, limit \\ 7) do
    GenServer.call(target, {:keycloak_realms, limit})
  end

  @spec aqua_vulnerability_reports(atom() | pid() | {atom(), any()} | {:via, atom(), any()}, integer()) ::
          list(map())
  def aqua_vulnerability_reports(target \\ @me, limit \\ 7) do
    GenServer.call(target, {:aqua_vulnerability_reports, limit})
  end

  @spec ip_address_pools(atom() | pid() | {atom(), any()} | {:via, atom(), any()}, integer()) ::
          list(CommonCore.MetalLB.IPAddressPool.t())
  def ip_address_pools(target \\ @me, limit \\ 7) do
    GenServer.call(target, {:ip_address_pools, limit})
  end

  @spec notebooks(atom() | pid() | {atom(), any()} | {:via, atom(), any()}, integer()) ::
          list(CommonCore.Notebooks.JupyterLabNotebook.t())
  def notebooks(target \\ @me, limit \\ 7) do
    GenServer.call(target, {:notebooks, limit})
  end

  @spec ferret_services(atom() | pid() | {atom(), any()} | {:via, atom(), any()}, integer()) ::
          list(CommonCore.FerretDB.FerretService.t())
  def ferret_services(target \\ @me, limit \\ 7) do
    GenServer.call(target, {:ferret_services, limit})
  end
end
