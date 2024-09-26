defmodule KubeServices.ET.StableVersionsWorker do
  @moduledoc false
  use GenServer
  use TypedStruct

  alias CommonCore.ET.StableVersionsReport
  alias KubeServices.ET.HomeBaseClient

  require Logger

  @state_opts ~w(home_base_client_pid )a

  typedstruct module: State do
    field :cached, StableVersionsReport.t()
    field :home_base_client_pid, :atom, default: HomeBaseClient
  end

  def start_link(args) do
    {init_args, genserver_opts} = args |> Keyword.put_new(:name, __MODULE__) |> Keyword.split(@state_opts)
    GenServer.start_link(__MODULE__, init_args, genserver_opts)
  end

  def init(args) do
    state = struct!(%State{}, args)

    if state.home_base_client_pid != nil do
      start_short_timer()
    end

    {:ok, state}
  end

  def handle_info(:fetch_versions, %State{home_base_client_pid: nil} = state) do
    Logger.info("Home base client is not set")
    {:noreply, %State{state | cached: StableVersionsReport.new!()}}
  end

  def handle_info(:fetch_versions, %State{home_base_client_pid: client} = state) do
    _ = start_timer()

    case HomeBaseClient.get_stable_versions(client) do
      {:ok, %StableVersionsReport{} = report} ->
        {:noreply, %State{state | cached: report}}

      {:error, _reason} ->
        {:noreply, state}
    end
  end

  def handle_call(:get_stable_versions, _from, %State{cached: cached} = state) do
    {:reply, cached, state}
  end

  @spec get_stable_versions() :: StableVersionsReport.t() | nil
  def get_stable_versions do
    GenServer.call(__MODULE__, :get_stable_versions)
  end

  defp start_timer do
    _ = Process.send_after(self(), :fetch_versions, 600_000)
    Logger.debug("Starting timer for next fetch stable versions in 600 seconds")
  end

  defp start_short_timer do
    _ = Process.send_after(self(), :fetch_versions, 5_000)
    Logger.debug("Starting short timer for next fetch stable versions in 5 seconds")
  end
end
