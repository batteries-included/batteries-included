defmodule KubeServices.RoboSRE.IssueWorker do
  @moduledoc """
  GenServer that manages the lifecycle of a single RoboSRE issue.

  Each issue gets its own worker process that handles:
  - Analysis phase: running analyzers to determine context
  - Remediation phase: executing handlers to fix the issue
  - Monitoring phase: checking if remediation was successful
  - State persistence: keeping issue state in sync with database

  The worker follows the state machine pattern defined in the RoboSRE documentation.
  """
  use GenServer
  use TypedStruct

  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.RoboSRE.Issue
  alias EventCenter.Database, as: DatabaseEventCenter

  require Logger

  typedstruct module: State do
    @typedoc "State for the IssueWorker GenServer"
    field :issue_id, CommonCore.Ecto.BatteryUUID.t()
    field :battery, SystemBattery.t()
    field :issue, Issue.t()
    field :analysis_timer, reference() | nil
    field :remediation_timer, reference() | nil
    field :monitoring_timer, reference() | nil
    field :retry_count, non_neg_integer(), default: 0
  end

  def start_link(opts) do
    issue = Keyword.fetch!(opts, :issue)
    battery = Keyword.fetch!(opts, :battery)

    GenServer.start_link(__MODULE__, {issue, battery}, name: via_name(issue.id))
  end

  @impl GenServer
  def init({%Issue{} = issue, %SystemBattery{} = battery}) do
    # Subscribe to issue updates for this specific issue
    :ok = DatabaseEventCenter.subscribe(:issue)

    Logger.info("IssueWorker started for issue #{issue.id}: #{issue.subject}")

    state = %State{
      issue_id: issue.id,
      battery: battery,
      issue: issue,
      retry_count: issue.retry_count || 0
    }

    # Start processing based on current status
    {:ok, state, {:continue, :process_issue}}
  end

  @impl GenServer
  def handle_continue(:process_issue, %State{issue: issue} = state) do
    case issue.status do
      :detected ->
        schedule_analysis(state)

      :analyzing ->
        schedule_analysis(state)

      :remediating ->
        schedule_remediation(state)

      :monitoring ->
        schedule_monitoring(state)

      status when status in [:resolved, :failed] ->
        Logger.info("Issue #{issue.id} is in terminal state #{status}, stopping worker")
        {:stop, :normal, state}

      _ ->
        Logger.warning("Issue #{issue.id} in unknown status #{issue.status}")
        {:noreply, state}
    end
  end

  @impl GenServer
  def handle_info({:update, %Issue{id: issue_id} = updated_issue}, %State{issue_id: issue_id} = state) do
    # This is an update for our issue
    new_state = %{state | issue: updated_issue}

    case updated_issue.status do
      status when status in [:resolved, :failed] ->
        Logger.info("Issue #{issue_id} reached terminal state #{status}, stopping worker")
        {:stop, :normal, new_state}

      _ ->
        {:noreply, new_state, {:continue, :process_issue}}
    end
  end

  @impl GenServer
  def handle_info({action, %Issue{} = _other_issue}, state) when action in [:insert, :update, :delete] do
    # This is for a different issue, ignore
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:multi, _multi_result}, state) do
    # Ignore multi operations
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:start_analysis, state) do
    Logger.debug("Starting analysis for issue #{state.issue_id}")

    # TODO: In future PRs, this will call actual analyzers
    # For now, just transition to analyzing state
    case update_issue_status(state.issue, :analyzing) do
      {:ok, updated_issue} ->
        # Simulate analysis delay then move to remediating
        new_state = %{state | issue: updated_issue}
        timer = Process.send_after(self(), :analysis_complete, 1000)
        {:noreply, %{new_state | analysis_timer: timer}}

      {:error, reason} ->
        Logger.error("Failed to update issue #{state.issue_id} to analyzing: #{inspect(reason)}")
        {:noreply, state}
    end
  end

  @impl GenServer
  def handle_info(:analysis_complete, state) do
    Logger.debug("Analysis complete for issue #{state.issue_id}")

    # TODO: In future PRs, this will determine which handlers to run
    # For now, just transition to remediating state
    case update_issue_status(state.issue, :remediating) do
      {:ok, updated_issue} ->
        new_state = %{state | issue: updated_issue, analysis_timer: nil}
        {:noreply, new_state, {:continue, :process_issue}}

      {:error, reason} ->
        Logger.error("Failed to update issue #{state.issue_id} to remediating: #{inspect(reason)}")
        {:noreply, state}
    end
  end

  @impl GenServer
  def handle_info(:start_remediation, state) do
    Logger.debug("Starting remediation for issue #{state.issue_id}")

    # TODO: In future PRs, this will call actual handlers
    # For now, just simulate remediation then move to monitoring
    timer = Process.send_after(self(), :remediation_complete, 2000)
    {:noreply, %{state | remediation_timer: timer}}
  end

  @impl GenServer
  def handle_info(:remediation_complete, state) do
    Logger.debug("Remediation complete for issue #{state.issue_id}")

    case update_issue_status(state.issue, :monitoring) do
      {:ok, updated_issue} ->
        new_state = %{state | issue: updated_issue, remediation_timer: nil}
        {:noreply, new_state, {:continue, :process_issue}}

      {:error, reason} ->
        Logger.error("Failed to update issue #{state.issue_id} to monitoring: #{inspect(reason)}")
        {:noreply, state}
    end
  end

  @impl GenServer
  def handle_info(:start_monitoring, state) do
    Logger.debug("Starting monitoring for issue #{state.issue_id}")

    # TODO: In future PRs, this will check if remediation was successful
    # For now, just simulate monitoring then resolve
    timer = Process.send_after(self(), :monitoring_complete, 3000)
    {:noreply, %{state | monitoring_timer: timer}}
  end

  @impl GenServer
  def handle_info(:monitoring_complete, state) do
    Logger.debug("Monitoring complete for issue #{state.issue_id}")

    # For now, just mark as resolved
    case update_issue_status(state.issue, :resolved) do
      {:ok, updated_issue} ->
        Logger.info("Issue #{state.issue_id} resolved successfully")
        new_state = %{state | issue: updated_issue, monitoring_timer: nil}
        {:stop, :normal, new_state}

      {:error, reason} ->
        Logger.error("Failed to resolve issue #{state.issue_id}: #{inspect(reason)}")
        {:noreply, state}
    end
  end

  @impl GenServer
  def handle_info(msg, state) do
    Logger.debug("IssueWorker #{state.issue_id} received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end

  @impl GenServer
  def terminate(reason, state) do
    Logger.debug("IssueWorker #{state.issue_id} terminating: #{inspect(reason)}")

    # Cancel any pending timers
    _ = if state.analysis_timer, do: Process.cancel_timer(state.analysis_timer)
    _ = if state.remediation_timer, do: Process.cancel_timer(state.remediation_timer)
    _ = if state.monitoring_timer, do: Process.cancel_timer(state.monitoring_timer)

    :ok
  end

  # Private functions

  defp schedule_analysis(state) do
    delay_ms = get_analysis_delay(state.battery)
    timer = Process.send_after(self(), :start_analysis, delay_ms)
    {:noreply, %{state | analysis_timer: timer}}
  end

  defp schedule_remediation(state) do
    timer = Process.send_after(self(), :start_remediation, 100)
    {:noreply, %{state | remediation_timer: timer}}
  end

  defp schedule_monitoring(state) do
    timer = Process.send_after(self(), :start_monitoring, 100)
    {:noreply, %{state | monitoring_timer: timer}}
  end

  defp get_analysis_delay(%SystemBattery{config: config}) do
    config.default_analysis_delay_ms || 200
  end

  defp update_issue_status(%Issue{} = issue, new_status) do
    ControlServer.RoboSRE.update_issue(issue, %{status: new_status})
  end

  defp via_name(issue_id) do
    {:via, Registry, {KubeServices.RoboSRE.Registry, issue_id}}
  end
end
