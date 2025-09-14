defmodule KubeServices.RoboSRE.StuckKubeStateHandler do
  @moduledoc false

  @behaviour KubeServices.RoboSRE.Handler

  use GenServer
  use TypedStruct

  alias CommonCore.RoboSRE.Issue
  alias CommonCore.RoboSRE.RemediationPlan
  alias KubeServices.RoboSRE.Handler

  require Logger

  @me __MODULE__

  typedstruct module: State do
    # Empty state for now since this handler is simple, but keeping pattern consistent
  end

  def start_link(opts \\ []) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, [], opts)
  end

  @impl GenServer
  def init(_opts) do
    state = %State{}
    {:ok, state}
  end

  @impl Handler
  def preflight(%Issue{} = issue) do
    GenServer.call(@me, {:preflight, issue})
  end

  @impl Handler
  def plan(%Issue{} = issue) do
    GenServer.call(@me, {:plan, issue})
  end

  @impl Handler
  def verify(%Issue{} = issue) do
    GenServer.call(@me, {:verify, issue})
  end

  @impl GenServer
  def handle_call({:preflight, %Issue{issue_type: :stuck_kubestate}}, _from, state) do
    # For now we always return ready
    # Restarting the kube state is a pretty safe operation
    {:reply, {:ok, :ready}, state}
  end

  @impl GenServer
  def handle_call({:preflight, _issue}, _from, state) do
    {:reply, {:error, :invalid_issue_type}, state}
  end

  @impl GenServer
  def handle_call({:plan, %Issue{issue_type: :stuck_kubestate}}, _from, state) do
    {:reply, {:ok, RemediationPlan.restart_kube_state()}, state}
  end

  @impl GenServer
  def handle_call({:plan, issue}, _from, state) do
    Logger.error("Planning remediation for unknown issue type (issue_id: #{issue.id}, subject: #{issue.subject})")
    {:reply, {:error, "Unknown issue type"}, state}
  end

  @impl GenServer
  def handle_call({:verify, %Issue{issue_type: :stuck_kubestate}}, _from, state) do
    {:reply, {:ok, :resolved}, state}
  end

  @impl GenServer
  def handle_call({:verify, issue}, _from, state) do
    Logger.error("Verifying remediation for unknown issue type (issue_id: #{issue.id}, subject: #{issue.subject})")
    {:reply, {:error, "Unknown issue type"}, state}
  end
end
