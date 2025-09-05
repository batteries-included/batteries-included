defmodule KubeServices.Stale.Watcher do
  @moduledoc """
  GenServer that watches for successful KubeSnapshot events and detects stale resources.

  When a KubeSnapshot is successful, this watcher will:
  1. Compare current resources against recent snapshots to identify potential stale resources
  2. Track staleness timing for each resource
  3. Create RoboSRE issues for resources that have been stale longer than the configured delay

  The watcher maintains an in-memory state of resources and their staleness tracking
  to avoid creating duplicate issues.
  """
  use GenServer
  use TypedStruct

  alias CommonCore.ApiVersionKind
  alias CommonCore.Resources.FieldAccessors
  alias ControlServer.RoboSRE.Issues
  alias ControlServer.SnapshotApply.KubeSnapshot
  alias EventCenter.KubeSnapshot, as: SnapshotEventCenter
  alias KubeServices.Stale

  require Logger

  @me __MODULE__

  typedstruct module: State do
    field :delay_ms, integer(), default: 900_000
    field :stale_resources, map(), default: %{}
    field :last_check_time, DateTime.t()
    field :snapshot_event_center, module(), default: SnapshotEventCenter

    def new!(opts) do
      delay_ms = Keyword.get(opts, :delay_ms, 900_000)
      snapshot_event_center = Keyword.get(opts, :snapshot_event_center, SnapshotEventCenter)

      struct!(__MODULE__,
        delay_ms: delay_ms,
        snapshot_event_center: snapshot_event_center
      )
    end
  end

  typedstruct module: StaleResourceEntry do
    field :namespace, String.t() | nil
    field :name, String.t()
    field :api_version_kind, map()
    field :first_seen_stale, DateTime.t()
    field :issue_created, boolean(), default: false
  end

  def start_link(opts \\ []) do
    opts = opts |> Keyword.put_new(:name, @me) |> Keyword.put_new(:delay, 900_000)
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl GenServer
  def init(opts) do
    state = State.new!(opts)
    :ok = state.snapshot_event_center.subscribe()
    Logger.info("Starting Watcher with delay: #{state.delay_ms}ms")

    {:ok, state}
  end

  @impl GenServer
  def handle_info(%SnapshotEventCenter.Payload{snapshot: %KubeSnapshot{status: :ok} = _snapshot}, state) do
    Logger.debug("Received successful KubeSnapshot, checking for stale resources delay #{state.delay_ms}ms")
    new_state = check_for_stale_resources(state)
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_info(%SnapshotEventCenter.Payload{snapshot: %KubeSnapshot{status: _other}}, state) do
    # Ignore failed snapshots
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(_other, state) do
    {:noreply, state}
  end

  # Check for stale resources and manage their lifecycle
  defp check_for_stale_resources(%State{} = state) do
    now = DateTime.utc_now()

    # Only proceed if we can safely delete
    if Stale.can_delete_safe?() do
      # Get currently stale resources
      current_stale_resources =
        Stale.find_potential_stale()
        |> Enum.map(&resource_to_entry/1)
        |> Enum.reject(&is_nil/1)
        |> Map.new(fn entry -> {{entry.api_version_kind, entry.namespace, entry.name}, entry} end)

      # Update our tracking state
      updated_stale_resources = update_stale_tracking(state.stale_resources, current_stale_resources, now)

      # Create issues for resources that have been stale long enough
      create_issues_for_eligible_resources(updated_stale_resources, state.delay_ms, now)

      %{state | stale_resources: updated_stale_resources, last_check_time: now}
    else
      Logger.debug("Cannot delete safely, skipping stale resource check")
      %{state | last_check_time: now}
    end
  end

  # Convert a resource map to a StaleResourceEntry
  defp resource_to_entry(resource) do
    namespace = FieldAccessors.namespace(resource)
    name = FieldAccessors.name(resource)
    api_version_kind = ApiVersionKind.resource_type(resource)

    if api_version_kind == nil do
      nil
    else
      %StaleResourceEntry{
        namespace: namespace,
        name: name,
        api_version_kind: api_version_kind,
        first_seen_stale: DateTime.utc_now()
      }
    end
  end

  # Update stale resource tracking state
  defp update_stale_tracking(existing_stale, current_stale, now) do
    # For each currently stale resource, either keep existing timing or start new tracking
    Map.new(current_stale, fn {key, entry} ->
      case Map.get(existing_stale, key) do
        nil ->
          # New stale resource
          {key, %{entry | first_seen_stale: now}}

        existing_entry ->
          {key, existing_entry}
      end
    end)
  end

  # Create RoboSRE issues for resources that have been stale long enough
  defp create_issues_for_eligible_resources(stale_resources, delay_ms, now) do
    stale_resources
    |> Enum.filter(fn {_key, entry} ->
      not entry.issue_created and
        DateTime.diff(now, entry.first_seen_stale, :millisecond) >= delay_ms
    end)
    |> Enum.each(fn {_key, entry} ->
      create_stale_resource_issue(entry)
    end)
  end

  # Create a RoboSRE issue for a stale resource
  defp create_stale_resource_issue(%StaleResourceEntry{} = entry) do
    subject = build_subject(entry)

    trigger_params = %{
      api_version_kind: entry.api_version_kind,
      namespace: entry.namespace,
      name: entry.name
    }

    issue_attrs = %{
      subject: subject,
      subject_type: :cluster_resource,
      issue_type: :stale_resource,
      trigger: :health_check,
      trigger_params: trigger_params,
      handler: :stale_resource
    }

    case Issues.create_issue(issue_attrs) do
      {:ok, issue} ->
        Logger.info("Created stale resource issue for #{subject} (issue_id: #{issue.id})")
        :ok

      {:error, changeset} ->
        Logger.error("Failed to create stale resource issue for #{subject}: #{inspect(changeset.errors)}")
        :error
    end
  end

  # Build the subject string for the issue
  defp build_subject(%StaleResourceEntry{namespace: namespace, name: name}) do
    case namespace do
      nil -> name
      "" -> name
      ns -> "#{ns}.#{name}"
    end
  end
end
