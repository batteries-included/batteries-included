defmodule KubeServices.RoboSRE.IssueWatcher do
  @moduledoc """
  Watches for new RoboSRE issues and starts IssueWorker processes to handle them.

  This GenServer subscribes to issue database events and starts workers
  for newly detected issues.
  """
  use GenServer
  use TypedStruct

  alias ControlServer.RoboSRE.Issues
  alias EventCenter.Database, as: DatabaseEventCenter
  alias KubeServices.RoboSRE.DynamicSupervisor, as: RoboSREDynamicSupervisor

  require Logger

  typedstruct module: State do
    field :analysis_delay_ms, integer(), default: 200

    # Modules for dependency injection / mocking in tests
    field :database_event_center, module(), default: DatabaseEventCenter
    field :dynamic_supervisor, module(), default: RoboSREDynamicSupervisor
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl GenServer
  def init(opts) do
    analysis_delay_ms = Keyword.get(opts, :analysis_delay_ms, 200)
    database_event_center = Keyword.get(opts, :database_event_center, DatabaseEventCenter)
    dynamic_supervisor = Keyword.get(opts, :dynamic_supervisor, RoboSREDynamicSupervisor)

    state = %State{
      analysis_delay_ms: analysis_delay_ms,
      database_event_center: database_event_center,
      dynamic_supervisor: dynamic_supervisor
    }

    # Start workers for any existing open issues
    spawn_link(fn -> start_existing_workers(state) end)

    # Subscribe to issue database events
    :ok = state.database_event_center.subscribe(:issue)

    {:ok, state}
  end

  @impl GenServer
  def handle_info({:insert, %{status: :detected} = issue}, %State{} = state) do
    Logger.info("RoboSRE: New issue detected: #{issue.subject} (#{issue.issue_type})")
    issue = Issues.get_issue!(issue.id)
    :ok = start_worker(issue, state)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:update, %{status: status} = issue}, state) when status in [:resolved, :failed] do
    Logger.info("RoboSRE: Issue #{issue.id} reached terminal state: #{status}")
    # The worker will handle its own cleanup when it detects the status change
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({action, %{} = _issue}, state) when action in [:update, :delete] do
    # For other updates, the worker will handle them
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:multi, _multi_result}, state) do
    # Ignore multi operations for now
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(msg, state) do
    Logger.debug("RoboSRE IssueWatcher received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end

  # Private functions

  defp start_existing_workers(%State{} = state) do
    # Find all open issues and start workers for them
    open_issues = Issues.list_open_issues()

    Enum.each(open_issues, fn issue ->
      :ok = start_worker(issue, state)
    end)

    Logger.info("RoboSRE: Started workers for #{length(open_issues)} existing open issues")
  end

  defp start_worker(
         %{} = issue,
         %State{dynamic_supervisor: dynamic_supervisor, analysis_delay_ms: analysis_delay_ms} = _state
       ) do
    case dynamic_supervisor.start_worker(issue: issue, analysis_delay_ms: analysis_delay_ms) do
      {:ok, _pid} ->
        Logger.debug("Started IssueWorker for issue #{issue.id}")
        :ok

      {:error, {:already_started, _pid}} ->
        Logger.debug("IssueWorker already running for issue #{issue.id}")
        :ok

      {:error, reason} ->
        Logger.error("Failed to start IssueWorker for issue #{issue.id}: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
