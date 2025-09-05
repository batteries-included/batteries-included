defmodule KubeServices.Stale.StaleResourceWatcher do
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
  alias ControlServer.RoboSRE
  alias ControlServer.SnapshotApply.KubeSnapshot
  alias EventCenter.KubeSnapshot, as: SnapshotEventCenter
  alias KubeServices.Stale

  require Logger

  @me __MODULE__

  typedstruct module: State do
    field :delay_ms, integer(), default: 900_000
    field :stale_resources, map(), default: %{}
    field :last_check_time, DateTime.t()
  end

  typedstruct module: StaleResourceEntry do
    field :namespace, String.t() | nil
    field :name, String.t()
    field :api_version_kind, map()
    field :first_seen_stale, DateTime.t()
    field :issue_created, boolean(), default: false
  end

  def start_link(opts \\ []) do
    {delay, opts} = Keyword.pop(opts, :delay, 900_000)
    opts = Keyword.put_new(opts, :name, @me)
    GenServer.start_link(__MODULE__, %{delay_ms: delay}, opts)
  end

  @impl GenServer
  def init(%{delay_ms: delay_ms}) do
    :ok = SnapshotEventCenter.subscribe()
    Logger.info("Starting StaleResourceWatcher with delay: #{delay_ms}ms")

    state = %State{
      delay_ms: delay_ms,
      stale_resources: %{},
      last_check_time: DateTime.utc_now()
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_info(%SnapshotEventCenter.Payload{snapshot: %KubeSnapshot{status: :ok} = _snapshot}, state) do
    Logger.debug("Received successful KubeSnapshot, checking for stale resources")
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
        |> Map.new(fn entry -> {resource_key(entry), entry} end)

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

    case build_api_version_kind(resource) do
      api_version_kind when not is_nil(api_version_kind) ->
        %StaleResourceEntry{
          namespace: namespace,
          name: name,
          api_version_kind: api_version_kind,
          first_seen_stale: DateTime.utc_now()
        }

      nil ->
        Logger.warning("Could not extract ApiVersionKind from resource: #{inspect(resource)}")
        nil

      error ->
        Logger.warning("Error converting resource to entry: #{inspect(error)}")
        nil
    end
  end

  # Build an ApiVersionKind map from a resource
  defp build_api_version_kind(resource) do
    with api_version when is_binary(api_version) <- Map.get(resource, "apiVersion"),
         kind when is_binary(kind) <- Map.get(resource, "kind") do
      %{
        "api_version" => api_version,
        "kind" => kind
      }
    else
      _ -> nil
    end
  end

  # Create a unique key for tracking resources
  defp resource_key(%StaleResourceEntry{namespace: namespace, name: name, api_version_kind: avk}) do
    type = ApiVersionKind.resource_type(avk)
    {type, namespace, name}
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
          # Keep existing tracking but update the entry data
          {key, %{entry | first_seen_stale: existing_entry.first_seen_stale, issue_created: existing_entry.issue_created}}
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
      "api_version_kind" => entry.api_version_kind,
      "first_seen_stale" => DateTime.to_iso8601(entry.first_seen_stale),
      "detection_source" => "stale_resource_watcher"
    }

    issue_attrs = %{
      subject: subject,
      subject_type: :cluster_resource,
      issue_type: :stale_resource,
      trigger: :health_check,
      trigger_params: trigger_params
    }

    case RoboSRE.create_issue(issue_attrs) do
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
