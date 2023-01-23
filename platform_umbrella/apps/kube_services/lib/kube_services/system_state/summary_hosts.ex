defmodule KubeServices.SystemState.SummaryHosts do
  alias ControlServer.SystemState.Summarizer
  alias CommonCore.SystemState.StateSummary
  alias EventCenter.SystemStateSummary
  use GenServer

  require Logger

  @me __MODULE__

  def start_link(opts) do
    {state_opts, genserver_opts} = Keyword.split(opts, [:summary])

    {:ok, pid} =
      result = GenServer.start_link(@me, state_opts, Keyword.merge([name: @me], genserver_opts))

    Logger.debug("#{@me} GenServer started with# #{inspect(pid)}.")
    result
  end

  @impl GenServer
  def init(opts) do
    Logger.debug("Starting SummaryHosts")
    :ok = SystemStateSummary.subscribe()

    state = %{
      summary: Keyword.get_lazy(opts, :summary, &Summarizer.cached/0)
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_info(%StateSummary{} = message, state) do
    new_state = %{state | summary: message}
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_call({:knative_host, service}, _from, %{summary: summary} = state) do
    {:reply, CommonCore.SystemState.Hosts.knative_host(summary, service), state}
  end

  @impl GenServer
  def handle_call(method, _from, %{summary: summary} = state) when is_atom(method) do
    {:reply, apply(CommonCore.SystemState.Hosts, method, [summary]), state}
  end

  @spec control_host(atom | pid | {atom, any} | {:via, atom, any}) :: String.t() | nil
  def control_host(target \\ @me) do
    GenServer.call(target, :control_host)
  end

  @spec gitea_host(atom | pid | {atom, any} | {:via, atom, any}) :: String.t() | nil
  def gitea_host(target \\ @me) do
    GenServer.call(target, :gitea_host)
  end

  @spec grafana_host(atom | pid | {atom, any} | {:via, atom, any}) :: String.t() | nil
  def grafana_host(target \\ @me) do
    GenServer.call(target, :grafana_host)
  end

  @spec vmselect_host(atom | pid | {atom, any} | {:via, atom, any}) :: String.t() | nil
  def vmselect_host(target \\ @me) do
    GenServer.call(target, :vmselect_host)
  end

  @spec vmagent_host(atom | pid | {atom, any} | {:via, atom, any}) :: String.t() | nil
  def vmagent_host(target \\ @me) do
    GenServer.call(target, :vmagent_host)
  end

  @spec harbor_host(atom | pid | {atom, any} | {:via, atom, any}) :: String.t() | nil
  def harbor_host(target \\ @me) do
    GenServer.call(target, :harbor_host)
  end

  @spec mailhog_host(atom | pid | {atom, any} | {:via, atom, any}) :: String.t() | nil
  def mailhog_host(target \\ @me) do
    GenServer.call(target, :mailhog_host)
  end

  @spec kratos_host(atom | pid | {atom, any} | {:via, atom, any}) :: String.t() | nil
  def kratos_host(target \\ @me) do
    GenServer.call(target, :kratos_host)
  end

  @spec kratos_admin_host(atom | pid | {atom, any} | {:via, atom, any}) :: String.t() | nil
  def kratos_admin_host(target \\ @me) do
    GenServer.call(target, :kratos_admin_host)
  end

  @spec notebooks_host(atom | pid | {atom, any} | {:via, atom, any}) :: String.t() | nil
  def notebooks_host(target \\ @me) do
    GenServer.call(target, :notebooks_host)
  end

  @spec knative_host(atom | pid | {atom, any} | {:via, atom, any}, map() | struct()) ::
          String.t() | nil
  def knative_host(target \\ @me, service) do
    GenServer.call(target, {:knative_host, service})
  end
end
