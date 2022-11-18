defmodule ControlServer.SystemState.Summarizer do
  use GenServer
  alias ControlServer.Batteries
  alias ControlServer.Knative
  alias ControlServer.Notebooks
  alias ControlServer.Postgres
  alias ControlServer.Redis
  alias ControlServer.Rook

  alias KubeExt.SystemState.StateSummary

  alias Ecto.Multi

  require Logger

  @type t :: %StateSummary{
          batteries: list(Batteries.SystemBattery.t()),
          postgres_clusters: list(Postgres.Cluster.t()),
          redis_clusters: list(Redis.FailoverCluster.t()),
          notebooks: list(Notebooks.JupyterLabNotebook.t()),
          ceph_clusters: list(Rook.CephCluster.t()),
          ceph_filesystems: list(Rook.CephFilesystem.t()),
          kube_state: map()
        }

  @me __MODULE__
  @default_refresh_time 30 * 1000
  @state_opts [
    :refresh_time
  ]

  def new(target \\ @me), do: GenServer.call(target, :new)
  def cached(target \\ @me), do: GenServer.call(target, :cached)
  def cached_field(target \\ @me, field), do: GenServer.call(target, {:cached, field})

  def start_link(opts) do
    {state_opts, gen_opts} =
      opts
      |> Keyword.put_new(:name, @me)
      |> Keyword.split(@state_opts)

    {:ok, pid} = result = GenServer.start_link(@me, state_opts, gen_opts)
    Logger.debug("#{@me} GenServer started with# #{inspect(pid)}.")
    result
  end

  @impl true
  def init(opts) do
    sleep_time = Keyword.get(opts, :refresh_time, @default_refresh_time)

    schedule_refresh(sleep_time)
    {:ok, %{last: new_summary!(), refresh_time: sleep_time}}
  end

  @impl true
  def handle_call(:new, _from, state) do
    new_summary = new_summary!()
    {:reply, new_summary, %{state | last: new_summary}}
  end

  @impl true
  def handle_call(:cached, _from, %{last: cached} = state) do
    {:reply, cached, state}
  end

  @impl true
  def handle_call({:cached, field}, _from, %{last: cached} = state) do
    {:reply, Map.get(cached, field), state}
  end

  @impl true
  def handle_info(:refresh, %{refresh_time: time} = state) do
    schedule_refresh(time)

    {:noreply, %{state | last: new_summary!()}}
  end

  defp schedule_refresh(refresh_time) do
    Process.send_after(self(), :refresh, refresh_time)
  end

  defp new_summary! do
    with {:ok, res} <- transaction() do
      struct(StateSummary, res)
    end
  end

  defp transaction do
    Multi.new()
    |> Multi.all(:batteries, Batteries.SystemBattery)
    |> Multi.all(:postgres_clusters, Postgres.Cluster)
    |> Multi.all(:redis_clusters, Redis.FailoverCluster)
    |> Multi.all(:notebooks, Notebooks.JupyterLabNotebook)
    |> Multi.all(:knative_services, Knative.Service)
    |> Multi.all(:ceph_clusters, Rook.CephCluster)
    |> Multi.all(:ceph_filesystems, Rook.CephFilesystem)
    |> Multi.run(:kube_state, fn _repo, _state ->
      {:ok, KubeExt.KubeState.snapshot()}
    end)
    |> ControlServer.Repo.transaction()
  end
end
