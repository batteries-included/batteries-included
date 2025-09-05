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

  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.RoboSRE.Issue
  alias EventCenter.Database, as: DatabaseEventCenter
  alias KubeServices.RoboSRE.Config

  require Logger

  defstruct [
    :issue_id,
    :battery,
    :issue,
    :analysis_timer,
    :remediation_timer,
    :monitoring_timer,
    :analysis_context,
    :remediation_plan,
    retry_count: 0
  ]

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

    state = %__MODULE__{
      issue_id: issue.id,
      battery: battery,
      issue: issue,
      retry_count: issue.retry_count || 0
    }

    # Start processing based on current status
    {:ok, state, {:continue, :process_issue}}
  end

  @impl GenServer
  def handle_continue(:process_issue, %{issue: issue} = state) do
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
  def handle_info({:update, %Issue{id: issue_id} = updated_issue}, %{issue_id: issue_id} = state) do
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

    case Config.get_analyzer(state.issue.issue_type) do
      {:ok, analyzer_module} ->
        handle_analysis_result(analyzer_module.analyze(state.issue), state)

      {:error, :not_found} ->
        Logger.error("No analyzer found for issue type #{state.issue.issue_type}")
        mark_issue_failed(state, "No analyzer available")
    end
  end

  @impl GenServer
  def handle_info(:analysis_complete, state) do
    Logger.debug("Analysis complete for issue #{state.issue_id}")

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

    case Config.get_handlers(state.issue.issue_type) do
      {:ok, [handler_module | _rest]} ->
        # Use the first handler for now - future versions can implement fallback logic
        case handler_module.plan_remediation(state.issue, state.analysis_context || %{}) do
          {:ok, remediation_plan} ->
            new_state = %{state | remediation_plan: remediation_plan}

            # Execute the first action
            case execute_next_action(new_state) do
              {:ok, updated_state} ->
                {:noreply, updated_state}

              {:error, reason} ->
                Logger.error("Remediation failed for issue #{state.issue_id}: #{reason}")
                handle_remediation_failure(state, reason)
            end

          {:error, reason} ->
            Logger.error("Failed to plan remediation for issue #{state.issue_id}: #{reason}")
            handle_remediation_failure(state, reason)
        end

      {:error, :not_found} ->
        Logger.error("No handlers found for issue type #{state.issue.issue_type}")
        handle_remediation_failure(state, "No handlers available")
    end
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

    case Config.get_handlers(state.issue.issue_type) do
      {:ok, [handler_module | _rest]} ->
        handle_monitoring_result(
          handler_module.verify_success(state.issue, state.analysis_context || %{}),
          state
        )

      {:error, :not_found} ->
        Logger.error("No handlers found for monitoring issue #{state.issue_id}")
        handle_monitoring_failure(state, "No handlers available")
    end
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

  # Handle analysis result from analyzer
  defp handle_analysis_result({:valid, context}, state) do
    Logger.info("Analysis successful for issue #{state.issue_id}")
    new_state = %{state | analysis_context: context}

    case update_issue_status(state.issue, :analyzing) do
      {:ok, updated_issue} ->
        # Analysis complete, move to remediation
        new_state = %{new_state | issue: updated_issue}
        timer = Process.send_after(self(), :analysis_complete, 100)
        {:noreply, %{new_state | analysis_timer: timer}}

      {:error, reason} ->
        Logger.error("Failed to update issue #{state.issue_id} to analyzing: #{inspect(reason)}")
        {:noreply, new_state}
    end
  end

  defp handle_analysis_result({:invalid, reason}, state) do
    Logger.info("Issue #{state.issue_id} marked as invalid: #{reason}")
    resolve_issue(state)
  end

  defp handle_analysis_result({:duplicate, existing_issue_id}, state) do
    Logger.info("Issue #{state.issue_id} is duplicate of #{existing_issue_id}")
    resolve_issue(state)
  end

  # Handle monitoring result from handler
  defp handle_monitoring_result({:ok, :resolved}, state) do
    Logger.info("Issue #{state.issue_id} successfully resolved")
    resolve_issue(state)
  end

  defp handle_monitoring_result({:ok, :pending}, state) do
    Logger.debug("Issue #{state.issue_id} remediation still pending, continuing to monitor")

    # Check again after a delay
    delay =
      case state.remediation_plan do
        %{success_check_delay_ms: delay_ms} -> delay_ms
        _ -> 30_000
      end

    timer = Process.send_after(self(), :start_monitoring, delay)
    {:noreply, %{state | monitoring_timer: timer}}
  end

  defp handle_monitoring_result({:error, reason}, state) do
    Logger.warning("Monitoring failed for issue #{state.issue_id}: #{reason}")
    handle_monitoring_failure(state, reason)
  end

  # Resolve an issue by updating its status
  defp resolve_issue(state) do
    case update_issue_status(state.issue, :resolved) do
      {:ok, _updated_issue} ->
        {:stop, :normal, state}

      {:error, error} ->
        Logger.error("Failed to resolve issue #{state.issue_id}: #{inspect(error)}")
        {:noreply, state}
    end
  end

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

  # Execute the next action in the remediation plan
  defp execute_next_action(%{remediation_plan: %{actions: [action | _remaining]}} = state) do
    case Config.get_handlers(state.issue.issue_type) do
      {:ok, [handler_module | _rest]} ->
        case handler_module.execute_action(action, state.issue) do
          {:ok, _result} ->
            # Action completed successfully, move to monitoring
            timer = Process.send_after(self(), :remediation_complete, 100)
            {:ok, %{state | remediation_timer: timer}}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, :not_found} ->
        {:error, "No handlers available"}
    end
  end

  defp execute_next_action(%{remediation_plan: %{actions: []}} = state) do
    # No more actions, move to monitoring
    timer = Process.send_after(self(), :remediation_complete, 100)
    {:ok, %{state | remediation_timer: timer}}
  end

  defp execute_next_action(_state) do
    # No remediation plan
    {:error, "No remediation plan available"}
  end

  # Handle remediation failure
  defp handle_remediation_failure(state, reason) do
    if state.retry_count < (state.issue.max_retries || 3) do
      Logger.warning("Remediation failed for issue #{state.issue_id}, retrying in 60s: #{reason}")

      # Update retry count and schedule retry
      new_retry_count = state.retry_count + 1

      case update_issue_with_retry(state.issue, new_retry_count) do
        {:ok, updated_issue} ->
          delay =
            case state.remediation_plan do
              %{retry_delay_ms: delay_ms} -> delay_ms
              _ -> 60_000
            end

          timer = Process.send_after(self(), :start_remediation, delay)
          new_state = %{state | issue: updated_issue, retry_count: new_retry_count, remediation_timer: timer}
          {:noreply, new_state}

        {:error, update_error} ->
          Logger.error("Failed to update retry count for issue #{state.issue_id}: #{inspect(update_error)}")
          mark_issue_failed(state, "Remediation failed and retry update failed")
      end
    else
      Logger.error("Issue #{state.issue_id} exceeded max retries, marking as failed")
      mark_issue_failed(state, "Exceeded maximum retry attempts")
    end
  end

  # Handle monitoring failure
  defp handle_monitoring_failure(state, reason) do
    Logger.error("Monitoring failed for issue #{state.issue_id}: #{reason}")
    mark_issue_failed(state, "Monitoring failed: #{reason}")
  end

  # Mark an issue as failed
  defp mark_issue_failed(state, reason) do
    case update_issue_status(state.issue, :failed) do
      {:ok, _updated_issue} ->
        Logger.error("Marked issue #{state.issue_id} as failed: #{reason}")
        {:stop, :normal, state}

      {:error, error} ->
        Logger.error("Failed to mark issue #{state.issue_id} as failed: #{inspect(error)}")
        {:noreply, state}
    end
  end

  # Update issue with retry count
  defp update_issue_with_retry(%Issue{} = issue, retry_count) do
    ControlServer.RoboSRE.update_issue(issue, %{retry_count: retry_count})
  end
end
