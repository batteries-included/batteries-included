defmodule KubeServices.RoboSRE.IssueWatcher do
  @moduledoc """
  Watches for new RoboSRE issues and starts IssueWorker processes to handle them.

  This GenServer subscribes to issue database events and starts workers
  for newly detected issues.
  """
  use GenServer
  use TypedStruct

  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.RoboSRE.Issue
  alias EventCenter.Database, as: DatabaseEventCenter
  alias KubeServices.RoboSRE.DynamicSupervisor, as: RoboSREDynamicSupervisor

  require Logger

  typedstruct module: State do
    @typedoc "State for the IssueWatcher GenServer"
    field :battery, SystemBattery.t()
  end

  def start_link(opts) do
    battery = Keyword.fetch!(opts, :battery)
    GenServer.start_link(__MODULE__, battery, name: via_name(battery))
  end

  @impl GenServer
  def init(%SystemBattery{} = battery) do
    # Subscribe to issue database events
    :ok = DatabaseEventCenter.subscribe(:issue)

    Logger.info("RoboSRE IssueWatcher started for battery #{battery.id}")

    # Start workers for any existing open issues
    spawn_link(fn -> start_existing_workers(battery) end)

    {:ok, %State{battery: battery}}
  end

  @impl GenServer
  def handle_info({:insert, %Issue{status: :detected} = issue}, %State{battery: battery} = state) do
    Logger.info("RoboSRE: New issue detected: #{issue.subject} (#{issue.issue_type})")

    case RoboSREDynamicSupervisor.start_issue_worker(battery, issue) do
      {:ok, _pid} ->
        Logger.debug("Started IssueWorker for issue #{issue.id}")

      {:error, {:already_started, _pid}} ->
        Logger.debug("IssueWorker already running for issue #{issue.id}")

      {:error, reason} ->
        Logger.error("Failed to start IssueWorker for issue #{issue.id}: #{inspect(reason)}")
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:update, %Issue{status: status} = issue}, state) when status in [:resolved, :failed] do
    Logger.info("RoboSRE: Issue #{issue.id} reached terminal state: #{status}")

    # The worker will handle its own cleanup when it detects the status change
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({action, %Issue{} = _issue}, state) when action in [:update, :delete] do
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

  defp start_existing_workers(%SystemBattery{} = battery) do
    # Find all open issues and start workers for them
    open_issues =
      ControlServer.RoboSRE.list_issues(%{
        filters: [
          %{field: :status, op: :in, value: [:detected, :analyzing, :remediating, :monitoring]}
        ]
      })

    case open_issues do
      {:ok, {issues, _meta}} ->
        Enum.each(issues, fn issue ->
          case RoboSREDynamicSupervisor.start_issue_worker(battery, issue) do
            {:ok, _pid} ->
              Logger.debug("Started IssueWorker for existing issue #{issue.id}")

            {:error, {:already_started, _pid}} ->
              Logger.debug("IssueWorker already running for existing issue #{issue.id}")

            {:error, reason} ->
              Logger.error("Failed to start IssueWorker for existing issue #{issue.id}: #{inspect(reason)}")
          end
        end)

        Logger.info("RoboSRE: Started workers for #{length(issues)} existing open issues")

      {:error, reason} ->
        Logger.error("Failed to load existing open issues: #{inspect(reason)}")
    end
  rescue
    error ->
      Logger.error("Error starting existing workers: #{inspect(error)}")
  end

  defp via_name(%SystemBattery{id: id}) do
    {:via, Registry, {KubeServices.Batteries.Registry, {id, __MODULE__}}}
  end
end
