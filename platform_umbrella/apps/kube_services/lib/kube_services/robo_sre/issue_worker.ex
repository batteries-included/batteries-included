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

  alias CommonCore.RoboSRE.Issue
  alias CommonCore.RoboSRE.RemediationPlan
  alias ControlServer.RoboSRE.Issues, as: IssuesContext
  alias ControlServer.RoboSRE.RemediationPlans, as: RemediationPlansContext
  alias EventCenter.Database, as: DatabaseEventCenter
  alias KubeServices.RoboSRE.DeleteResourceExecutor
  alias KubeServices.RoboSRE.RestartKubeStateExecutor
  alias KubeServices.RoboSRE.StaleResourceHandler
  alias KubeServices.RoboSRE.StuckKubeStateHandler

  require Logger

  typedstruct module: State do
    # Input
    field :issue, Issue.t(), enforce: true
    field :analysis_delay_ms, integer(), default: 200
    field :analysis_timer, reference(), enforce: false
    field :remediation_timer, reference(), enforce: false
    field :verify_timer, reference(), enforce: false
    field :plan_id, CommonCore.Ecto.BatteryUUID.t() | nil, default: nil
    # modules for dependency injection / mocking in tests
    field :delete_resource_executor, module(), default: DeleteResourceExecutor
    field :restart_kube_state_executor, module(), default: RestartKubeStateExecutor
    field :database_event_center, module(), default: DatabaseEventCenter
    field :issues_context, module(), default: IssuesContext
    field :remediation_plans_context, module(), default: RemediationPlansContext
    field :stale_resource_handler, module(), default: StaleResourceHandler
    field :stuck_kube_state_handler, module(), default: StuckKubeStateHandler

    def new!(opts \\ []) do
      issue = Keyword.fetch!(opts, :issue)
      analysis_delay_ms = Keyword.get(opts, :analysis_delay_ms, 200)
      database_event_center = Keyword.get(opts, :database_event_center, DatabaseEventCenter)
      delete_resource_executor = Keyword.get(opts, :delete_resource_executor, DeleteResourceExecutor)
      restart_kube_state_executor = Keyword.get(opts, :restart_kube_state_executor, RestartKubeStateExecutor)
      issues_context = Keyword.get(opts, :issues_context, IssuesContext)
      remediation_plans_context = Keyword.get(opts, :remediation_plans_context, RemediationPlansContext)
      stale_resource_handler = Keyword.get(opts, :stale_resource_handler, StaleResourceHandler)
      stuck_kube_state_handler = Keyword.get(opts, :stuck_kube_state_handler, StuckKubeStateHandler)

      struct!(__MODULE__,
        issue: issue,
        analysis_delay_ms: analysis_delay_ms,
        database_event_center: database_event_center,
        delete_resource_executor: delete_resource_executor,
        restart_kube_state_executor: restart_kube_state_executor,
        issues_context: issues_context,
        remediation_plans_context: remediation_plans_context,
        stale_resource_handler: stale_resource_handler,
        stuck_kube_state_handler: stuck_kube_state_handler
      )
    end
  end

  def start_link(opts \\ []) do
    issue = Keyword.fetch!(opts, :issue)
    GenServer.start_link(__MODULE__, opts, name: via(issue.id))
  end

  def via(issue_id) do
    {:via, Registry, {KubeServices.RoboSRE.Registry, issue_id}}
  end

  @impl GenServer
  def init(opts) do
    state = State.new!(opts)

    # Subscribe to issue updates for this specific issue
    :ok = state.database_event_center.subscribe(:issue)

    Logger.info("IssueWorker started for issue #{state.issue.id}: #{state.issue.subject}", issue_id: state.issue.id)
    # Start processing based on current status
    {:ok, state, {:continue, :process_issue}}
  end

  @impl GenServer
  def handle_continue(:process_issue, %State{issue: _issue} = state) do
    process_issue(state)
  end

  @impl GenServer
  def handle_info(:run_analysis, %State{issue: issue} = state) do
    Logger.debug("Starting analysis for issue #{issue.id}", issue_id: issue.id)

    with {:ok, refreshed_state} <- refresh_and_validate_issue_state(state, [:detected, :analyzing]),
         {:ok, updated_issue} <- state.issues_context.update_issue(refreshed_state.issue, %{status: :analyzing}),
         {:ok, result, updated_state} <- execute_analysis(%{refreshed_state | issue: updated_issue}) do
      Logger.debug("Analysis completed for issue #{issue.id} with result #{inspect(result)}", issue_id: issue.id)

      case result do
        :ready -> transition_to_planning(updated_state)
        :skip -> transition_to_resolved(updated_state)
      end
    else
      {:error, :issue_state_changed, current_state} ->
        Logger.info(
          "Issue #{issue.id} state changed, re-processing previous #{issue.status} now #{current_state.issue.status}",
          issue_id: issue.id
        )

        process_issue(current_state)

      {:error, reason, updated_state} ->
        Logger.error("Analysis failed for issue #{issue.id}: #{inspect(reason)}", issue_id: issue.id)
        transition_to_failed(updated_state)
    end
  end

  @impl GenServer
  def handle_info(:run_planning, %State{issue: issue} = state) do
    with {:ok, refreshed_state} <- refresh_and_validate_issue_state(state, [:planning]),
         {:ok, updated_state} <- execute_planning(refreshed_state) do
      transition_to_remediating(updated_state)
    else
      {:error, :issue_state_changed, current_state} ->
        Logger.info(
          "Issue #{issue.id} state changed, re-processing. Previous: #{issue.status} Current: #{current_state.issue.status}",
          issue_id: issue.id
        )

        process_issue(current_state)

      {:error, reason, updated_state} ->
        Logger.error("Planning failed: #{inspect(reason)}", issue_id: state.issue.id)
        transition_to_failed(updated_state)
    end
  end

  @impl GenServer
  def handle_info(:run_remediation, %{issue: %{status: :remediating}} = state) do
    with {:ok, refreshed_state} <- refresh_and_validate_issue_state(state, [:remediating]),
         {:ok, updated_state} <- execute_current_action(refreshed_state) do
      check_plan_completion(updated_state)
    else
      {:error, :issue_state_changed, current_state} ->
        Logger.debug("Issue #{state.issue.id} state changed, re-processing", issue_id: state.issue.id)
        process_issue(current_state)

      {:error, reason, updated_state} ->
        Logger.error("Remediation action failed: #{inspect(reason)}", issue_id: state.issue.id)
        handle_remediation_failure(updated_state)
    end
  end

  @impl GenServer
  def handle_info(:run_remediation, %{issue: %{status: status}} = state) do
    Logger.debug("Ignoring :run_remediation message, issue status is #{status} (not remediating)",
      issue_id: state.issue.id
    )

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:run_verify, state) do
    with {:ok, refreshed_state} <- refresh_and_validate_issue_state(state, [:verifying]),
         {:ok, result, updated_state} <- execute_verify(refreshed_state) do
      case result do
        :resolved -> transition_to_resolved(updated_state)
        :pending -> handle_verify_pending(updated_state)
      end
    else
      {:error, :issue_state_changed, current_state} ->
        Logger.debug("Issue #{state.issue.id} state changed, re-processing", issue_id: state.issue.id)
        process_issue(current_state)

      {:error, reason, updated_state} ->
        Logger.error("Verification failed: #{inspect(reason)}", issue_id: state.issue.id)
        transition_to_failed(updated_state)
    end
  end

  @impl GenServer
  def handle_info(
        {:update, %{id: issue_id} = _updated_issue},
        %{issue: %{id: issue_id} = old_issue, issues_context: issues_context} = state
      ) do
    # Issue was updated, sync our local state
    Logger.debug("Issue #{issue_id} was updated, syncing state", issue_id: issue_id)
    new_issue = issues_context.get_issue!(issue_id)
    state = %{state | issue: new_issue}

    # use status and updated_at to determine if we need to re-process
    if old_issue.status == new_issue.status && old_issue.updated_at == new_issue.updated_at do
      {:noreply, state}
    else
      Logger.info("Issue #{issue_id} status changed from #{old_issue.status} to #{new_issue.status}", issue_id: issue_id)
      process_issue(state)
    end
  end

  @impl GenServer
  def handle_info({:delete, %{id: issue_id}}, %{issue: %{id: issue_id}} = state) do
    Logger.info("Issue #{issue_id} has been deleted, stopping worker", issue_id: issue_id)
    {:stop, :normal, state}
  end

  @impl GenServer
  def handle_info(_msg, state) do
    # Since we can get updates for all issues, ignore ones not for us
    {:noreply, state}
  end

  # Helper function to refresh issue state from database and validate/update expected status
  defp refresh_and_validate_issue_state(%State{issue: issue, issues_context: issues_context} = state, expected_statuses) do
    refreshed_issue = issues_context.get_issue!(issue.id)

    if refreshed_issue.status in expected_statuses do
      # Already in expected state
      {:ok, %{state | issue: refreshed_issue}}
    else
      # state transition
      {:error, :issue_state_changed, %{state | issue: refreshed_issue}}
    end
  end

  defp process_issue(%State{issue: issue} = state) do
    case issue.status do
      :detected ->
        schedule_analysis(state)

      :analyzing ->
        schedule_analysis(state)

      :planning ->
        schedule_planning(state)

      :remediating ->
        schedule_remediation(state)

      :verifying ->
        schedule_verify(state)

      status when status in [:resolved, :failed] ->
        Logger.info("Issue #{issue.id} is in terminal state #{status}, stopping worker", issue_id: issue.id)
        {:stop, :normal, state}

      _ ->
        Logger.warning("Issue #{issue.id} in unknown status #{issue.status}", issue_id: issue.id)
        {:noreply, state}
    end
  end

  defp cancel_all_timers(state) do
    _ref = if state.analysis_timer, do: Process.cancel_timer(state.analysis_timer)
    _ref = if state.remediation_timer, do: Process.cancel_timer(state.remediation_timer)
    _ref = if state.verify_timer, do: Process.cancel_timer(state.verify_timer)

    %{state | analysis_timer: nil, remediation_timer: nil, verify_timer: nil}
  end

  defp schedule_analysis(%{analysis_delay_ms: delay_ms} = state) do
    Logger.debug("Scheduling analysis in #{delay_ms}ms for issue #{state.issue.id}", issue_id: state.issue.id)
    timer_ref = Process.send_after(self(), :run_analysis, delay_ms)
    {:noreply, %{cancel_all_timers(state) | analysis_timer: timer_ref}}
  end

  defp schedule_planning(state, delay \\ 0) do
    Logger.debug("Scheduling planning for issue #{state.issue.id}", issue_id: state.issue.id)
    timer_ref = Process.send_after(self(), :run_planning, delay)
    {:noreply, %{cancel_all_timers(state) | remediation_timer: timer_ref}}
  end

  defp schedule_remediation(state, delay \\ 0)

  defp schedule_remediation(%{plan_id: plan_id} = state, delay) when not is_nil(plan_id) do
    # Schedule immediate execution for the first/next action
    timer_ref = Process.send_after(self(), :run_remediation, delay)
    {:noreply, %{cancel_all_timers(state) | remediation_timer: timer_ref}}
  end

  defp schedule_remediation(%{plan_id: nil} = state, _delay) do
    Logger.error("Cannot schedule remediation without plan_id", issue_id: state.issue.id)
    transition_to_failed(state)
  end

  defp schedule_verify(state, delay \\ 0) do
    # Schedule immediate monitoring check for existing monitoring state
    timer_ref = Process.send_after(self(), :run_verify, delay)
    {:noreply, %{cancel_all_timers(state) | verify_timer: timer_ref}}
  end

  defp execute_analysis(%{issue: issue} = state) do
    handler_module = get_handler(state)

    case handler_module.preflight(issue) do
      {:ok, :ready} ->
        Logger.debug("Preflight check passed for issue #{issue.id}", issue_id: issue.id)
        {:ok, :ready, state}

      {:ok, :skip} ->
        Logger.info("Preflight check indicates issue #{issue.id} should be skipped", issue_id: issue.id)
        {:ok, :skip, state}

      {:error, reason} ->
        Logger.error("Preflight check failed for issue #{issue.id}: #{inspect(reason)}", issue_id: issue.id)
        {:error, reason, state}
    end
  end

  defp execute_planning(%{issue: issue} = state) do
    case create_new_plan(state) do
      {:ok, plan} ->
        {:ok, %{state | plan_id: plan.id}}

      {:error, reason} ->
        Logger.error("Planning failed for issue #{issue.id}: #{inspect(reason)}", issue_id: issue.id)
        {:error, reason, state}
    end
  end

  defp create_new_plan(%{issue: issue, remediation_plans_context: plans_context} = state) do
    handler_module = get_handler(state)

    with {:ok, plan} <- handler_module.plan(state),
         {:ok, saved_plan} <- plans_context.create_remediation_plan(Map.put(plan, :issue_id, issue.id)) do
      Logger.debug("Created remediation plan with #{length(saved_plan.actions)} actions", issue_id: issue.id)
      {:ok, saved_plan}
    else
      {:error, changeset} when is_map(changeset) and is_map_key(changeset, :errors) ->
        Logger.error("Failed to save remediation plan: #{inspect(changeset.errors)}", issue_id: issue.id)
        {:error, :failed_to_save_plan}

      {:error, reason, _updated_state} ->
        Logger.error("Failed to create remediation plan: #{inspect(reason)}", issue_id: issue.id)
        {:error, reason}

      {:error, reason} ->
        Logger.error("Failed to create remediation plan: #{inspect(reason)}", issue_id: issue.id)
        {:error, reason}
    end
  end

  defp execute_current_action(%{plan_id: plan_id, remediation_plans_context: plans_context} = state)
       when not is_nil(plan_id) do
    with %RemediationPlan{} = plan <- plans_context.get_remediation_plan(plan_id),
         {:actions_remaining, true} <- {:actions_remaining, plan.current_action_index < length(plan.actions)},
         action when not is_nil(action) <- Enum.at(plan.actions, plan.current_action_index),
         executor = get_executor(state, plan),
         Logger.debug("Executing action #{plan.current_action_index + 1}/#{length(plan.actions)}: #{action.action_type}",
           issue_id: state.issue.id
         ),
         {:ok, result} <- executor.execute(action),
         Logger.debug("Action completed successfully: #{inspect(result)} for issue #{state.issue.id}",
           issue_id: state.issue.id
         ),
         # Save the result to the database, but continue even if this fails
         {:ok, _updated_action} <- plans_context.update_action_result(action.id, to_result_map(result)) do
      {:ok, state}
    else
      nil ->
        Logger.error("Remediation plan #{plan_id} not found", issue_id: state.issue.id)
        {:error, :plan_not_found, state}

      {:actions_remaining, false} ->
        Logger.debug("All actions completed for plan #{plan_id}, skipping execution", issue_id: state.issue.id)
        # All actions are complete, return success so completion check can handle transition
        {:ok, state}

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error("Failed to save action result: #{inspect(changeset.errors)}", issue_id: state.issue.id)
        # Continue anyway since the action itself succeeded
        {:ok, state}

      {:error, reason} ->
        Logger.error("Action failed: #{inspect(reason)} for issue #{state.issue.id}", issue_id: state.issue.id)
        {:error, reason, state}
    end
  end

  defp execute_current_action(%{plan_id: nil} = state) do
    Logger.error("No plan ID available for remediation", issue_id: state.issue.id)
    {:error, :no_plan_id, state}
  end

  defp execute_verify(%{issue: issue} = state) do
    handler_module = get_handler(state)

    case handler_module.verify(issue) do
      {:ok, :resolved} ->
        Logger.info("Verification successful, issue #{issue.id} is resolved", issue_id: issue.id)
        {:ok, :resolved, state}

      {:ok, :pending} ->
        Logger.debug("Verification indicates issue #{issue.id} is still pending", issue_id: issue.id)
        {:ok, :pending, state}

      {:error, reason} ->
        Logger.error("Verification failed for issue #{issue.id}: #{inspect(reason)}", issue_id: issue.id)
        {:error, reason, state}
    end
  end

  defp check_plan_completion(%{plan_id: plan_id, remediation_plans_context: plans_context} = state)
       when not is_nil(plan_id) do
    with %RemediationPlan{} = plan <- plans_context.get_remediation_plan(plan_id),
         next_index = plan.current_action_index + 1,
         {:ok, _updated_plan} <- plans_context.update_remediation_plan(plan, %{current_action_index: next_index}) do
      if next_index >= length(plan.actions) do
        # All actions completed, schedule monitoring
        Logger.debug("All remediation actions completed, transitioning to monitoring", issue_id: state.issue.id)
        transition_to_monitoring(state)
      else
        # More actions to execute
        Logger.debug("Scheduling next action (#{next_index + 1}/#{length(plan.actions)})", issue_id: state.issue.id)
        schedule_remediation(state)
      end
    else
      nil ->
        Logger.error("Plan #{plan_id} not found for completion check", issue_id: state.issue.id)
        transition_to_failed(state)

      {:error, changeset} ->
        Logger.error("Failed to update plan action index: #{inspect(changeset.errors)}", issue_id: state.issue.id)
        # Still try to continue based on completed vs remaining actions
        # Re-fetch plan to get current state for fallback logic
        case plans_context.get_remediation_plan(plan_id) do
          %RemediationPlan{} = plan ->
            next_index = plan.current_action_index + 1

            if next_index >= length(plan.actions) do
              transition_to_monitoring(state)
            else
              schedule_remediation(state)
            end

          nil ->
            Logger.error("Plan #{plan_id} not found for fallback completion check", issue_id: state.issue.id)
            transition_to_failed(state)
        end
    end
  end

  defp check_plan_completion(%{plan_id: nil} = state) do
    Logger.error("No plan ID available for completion check", issue_id: state.issue.id)
    transition_to_failed(state)
  end

  defp handle_remediation_failure(
         %{issue: issue, issues_context: issues_context, remediation_plans_context: plans_context, plan_id: plan_id} =
           state
       )
       when not is_nil(plan_id) do
    retry_count = issue.retry_count + 1

    if retry_count >= issue.max_retries do
      Logger.error("Issue #{issue.id} exceeded max retries (#{issue.max_retries})", issue_id: issue.id)
      transition_to_failed(state)
    else
      Logger.info("Retrying remediation for issue #{issue.id} (attempt #{retry_count + 1}/#{issue.max_retries})",
        issue_id: issue.id
      )

      with {:ok, updated_issue} <- issues_context.update_issue(issue, %{retry_count: retry_count}),
           state = %{state | issue: updated_issue},
           %RemediationPlan{} = plan <- plans_context.get_remediation_plan(plan_id),
           {:ok, _updated_plan} <- plans_context.update_remediation_plan(plan, %{current_action_index: 0}) do
        delay_ms = plan.retry_delay_ms
        schedule_remediation(state, delay_ms)
      else
        {:error, changeset} ->
          Logger.error("Failed to update retry count: #{inspect(changeset.errors)}", issue_id: issue.id)
          transition_to_failed(state)

        nil ->
          Logger.error("Plan #{plan_id} not found for retry", issue_id: issue.id)
          transition_to_failed(state)
      end
    end
  end

  defp handle_remediation_failure(%{plan_id: nil} = state) do
    Logger.error("Cannot handle remediation failure without plan_id", issue_id: state.issue.id)
    transition_to_failed(state)
  end

  defp handle_verify_pending(
         %{issue: issue, issues_context: issues_context, remediation_plans_context: plans_context, plan_id: plan_id} =
           state
       )
       when not is_nil(plan_id) do
    retry_count = issue.retry_count + 1

    with %RemediationPlan{} = plan <- plans_context.get_remediation_plan(plan_id),
         {:within_retry_limit, true} <- {:within_retry_limit, retry_count < plan.max_retries} do
      Logger.debug("Issue #{issue.id} still pending, retrying monitoring (#{retry_count}/#{plan.max_retries})",
        issue_id: issue.id
      )

      case issues_context.update_issue(issue, %{retry_count: retry_count}) do
        {:ok, updated_issue} ->
          delay_ms = plan.retry_delay_ms
          schedule_verify(%{state | issue: updated_issue}, delay_ms)

        {:error, changeset} ->
          Logger.error("Failed to update retry count during monitoring: #{inspect(changeset.errors)}", issue_id: issue.id)
          transition_to_failed(state)
      end
    else
      nil ->
        Logger.error("Plan #{plan_id} not found for verify pending", issue_id: state.issue.id)
        transition_to_failed(state)

      {:within_retry_limit, false} ->
        # We need to get the plan again to access max_retries in the error case
        case plans_context.get_remediation_plan(plan_id) do
          %RemediationPlan{} = plan ->
            Logger.error("Issue #{issue.id} monitoring exceeded max retries (#{plan.max_retries})", issue_id: issue.id)

          nil ->
            Logger.error("Issue #{issue.id} monitoring exceeded max retries", issue_id: issue.id)
        end

        transition_to_failed(state)
    end
  end

  defp handle_verify_pending(%{plan_id: nil} = state) do
    Logger.error("Cannot handle verify pending without plan_id", issue_id: state.issue.id)
    transition_to_failed(state)
  end

  defp transition_to_planning(%{issue: issue, issues_context: issues_context} = state) do
    Logger.info("Transitioning issue #{issue.id} to planning", issue_id: issue.id)

    case issues_context.update_issue(issue, %{status: :planning, retry_count: 0}) do
      {:ok, updated_issue} ->
        schedule_planning(%{state | issue: updated_issue})

      {:error, changeset} ->
        Logger.error("Failed to update issue status to planning: #{inspect(changeset.errors)}", issue_id: issue.id)
        transition_to_failed(state)
    end
  end

  defp transition_to_remediating(%{issue: issue, issues_context: issues_context} = state) do
    Logger.info("Transitioning issue #{issue.id} to remediating", issue_id: issue.id)

    case issues_context.update_issue(issue, %{status: :remediating, retry_count: 0}) do
      {:ok, updated_issue} ->
        # Plan should already be set in state from planning phase
        schedule_remediation(%{state | issue: updated_issue})

      {:error, changeset} ->
        Logger.error("Failed to update issue status to remediating: #{inspect(changeset.errors)}", issue_id: issue.id)
        transition_to_failed(state)
    end
  end

  defp transition_to_monitoring(
         %{issue: issue, issues_context: issues_context, remediation_plans_context: plans_context, plan_id: plan_id} =
           state
       )
       when not is_nil(plan_id) do
    Logger.info("Transitioning issue #{issue.id} to verifying", issue_id: issue.id)

    # Load plan to get success delay
    case plans_context.get_remediation_plan(plan_id) do
      %RemediationPlan{} = plan ->
        case issues_context.update_issue(issue, %{status: :verifying, retry_count: 0}) do
          {:ok, updated_issue} ->
            # Schedule verifying after success delay
            delay_ms = plan.success_delay_ms
            schedule_verify(%{state | issue: updated_issue}, delay_ms)

          {:error, changeset} ->
            Logger.error("Failed to update issue status to verifying: #{inspect(changeset.errors)}", issue_id: issue.id)
            transition_to_failed(state)
        end

      nil ->
        Logger.error("Plan #{plan_id} not found for monitoring transition", issue_id: issue.id)
        transition_to_failed(state)
    end
  end

  defp transition_to_resolved(%{issue: issue, issues_context: issues_context} = state) do
    Logger.info("Issue #{issue.id} resolved successfully", issue_id: issue.id)

    case issues_context.update_issue(issue, %{status: :resolved, retry_count: 0}) do
      {:ok, updated_issue} ->
        Logger.info("Issue #{issue.id} is in terminal state resolved, stopping worker", issue_id: issue.id)
        {:stop, :normal, %{state | issue: updated_issue}}

      {:error, changeset} ->
        Logger.error("Failed to update issue status to resolved: #{inspect(changeset.errors)}", issue_id: issue.id)
        # Still consider it resolved locally even if DB update fails
        Logger.info("Issue #{issue.id} is in terminal state resolved, stopping worker", issue_id: issue.id)
        {:stop, :normal, state}
    end
  end

  defp transition_to_failed(%{issue: issue, issues_context: issues_context} = state) do
    Logger.error("Issue #{issue.id} failed", issue_id: issue.id)

    case issues_context.update_issue(issue, %{status: :failed}) do
      {:ok, updated_issue} ->
        Logger.info("Issue #{issue.id} is in terminal state failed, stopping worker", issue_id: issue.id)
        {:stop, :normal, %{state | issue: updated_issue}}

      {:error, changeset} ->
        Logger.error("Failed to update issue status to failed: #{inspect(changeset.errors)}", issue_id: issue.id)
        # Still consider it failed locally even if DB update fails
        Logger.info("Issue #{issue.id} is in terminal state failed, stopping worker", issue_id: issue.id)
        {:stop, :normal, state}
    end
  end

  defp get_handler(%State{issue: issue} = state) do
    case issue.handler do
      :stale_resource -> state.stale_resource_handler
      :stuck_kubestate -> state.stuck_kube_state_handler
      _ -> raise "Unknown handler #{issue.handler}"
    end
  end

  defp get_executor(
         %State{
           delete_resource_executor: delete_resource_executor,
           restart_kube_state_executor: restart_kube_state_executor
         } = state,
         %{actions: actions, current_action_index: current_action_index} = _plan
       ) do
    action = Enum.at(actions, current_action_index)

    case action.action_type do
      :delete_resource -> delete_resource_executor
      :restart_kube_state -> restart_kube_state_executor
      _ -> raise "Unknown action type #{action.action_type}"
    end
  end

  defp to_result_map(result) when is_map(result), do: result
  defp to_result_map(result), do: %{"result" => result}
end
