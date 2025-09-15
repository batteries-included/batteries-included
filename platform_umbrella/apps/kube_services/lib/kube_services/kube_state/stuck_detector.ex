defmodule KubeServices.KubeState.StuckDetector do
  @moduledoc """

  This detector periodically compares a snapshot of the current kubestate
  with the actual kubestate in the cluster. If there are there are differences,
  above a per-configured threshold (percentage of investigated resources
  that were drifted per type), then it will create a RoboSRE issue to investigate.

  For each API version kind (e.g. Pod, Deployment, Service) there is a
  configurable percentage of resource we will explore. For example we might
  do 15% of pods and 10% of most things.

  Currently we consider resources are drifting if:

  - They exist in the snapshot but not in the cluster
  - The Resource Hash has changed.
  """

  use GenServer
  use TypedStruct

  import CommonCore.Resources.FieldAccessors

  alias CommonCore.ApiVersionKind
  alias CommonCore.ConnectionPool
  alias CommonCore.Resources.Hashing
  alias ControlServer.RoboSRE.Issues
  alias KubeServices.K8s.Client

  require Logger

  typedstruct module: State do
    @default_sample_percent 0.10
    # sample percentages by resource type
    @type_sample_percentages %{
      pod: 0.15,
      config_map: 0.25,
      secret: 0.25,
      namespace: 1.0
    }

    # Default drift threshold - if more than 8% of sampled resources are drifted, create an issue
    @default_drift_threshold 0.08

    field :check_interval, integer(), default: 3_600_000
    field :last_check_time, DateTime.t()
    field :type_sample_percentages, map(), default: @type_sample_percentages
    field :default_sample_percent, float(), default: @default_sample_percent
    field :drift_threshold, float(), default: @default_drift_threshold
    field :timer_ref, reference()
    field :connection, any()

    # Dependencies for testing
    field :kube_state, module(), default: KubeServices.KubeState
    field :client, module(), default: Client
    field :issues_context, module(), default: Issues

    def new!(opts) do
      check_interval = Keyword.get(opts, :check_interval, 3_600_000)
      type_sample_percentages = Keyword.get(opts, :sample_percentages, @type_sample_percentages)
      default_sample_percent = Keyword.get(opts, :default_sample_percentage, @default_sample_percent)
      drift_threshold = Keyword.get(opts, :drift_threshold, @default_drift_threshold)
      kube_state = Keyword.get(opts, :kube_state, KubeServices.KubeState)
      client = Keyword.get(opts, :client, Client)
      issues_context = Keyword.get(opts, :issues_context, Issues)
      connection = Keyword.get(opts, :connection)

      struct!(__MODULE__,
        check_interval: check_interval,
        type_sample_percentages: type_sample_percentages,
        default_sample_percent: default_sample_percent,
        drift_threshold: drift_threshold,
        kube_state: kube_state,
        client: client,
        issues_context: issues_context,
        connection: connection
      )
    end

    def get_sample_percentage(
          %{type_sample_percentages: type_sample_percentages, default_sample_percent: default_sample_percent},
          api_version_kind
        ) do
      Map.get(type_sample_percentages, api_version_kind, default_sample_percent)
    end
  end

  def start_link(opts \\ []) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: Keyword.fetch!(opts, :name))
  end

  @impl GenServer
  def init(opts) do
    state = State.new!(opts)

    # Get connection if not provided in opts
    connection =
      if state.connection do
        state.connection
      else
        connection_fn = Keyword.get(opts, :connection_fn, &ConnectionPool.get!/0)
        connection_fn.()
      end

    state = %{state | connection: connection}

    Logger.info("StuckDetector started with check interval: #{state.check_interval}ms")
    {:ok, schedule_check(state)}
  end

  @doc """
  Trigger a check immediately.
  """
  def check_now(server \\ __MODULE__) do
    GenServer.call(server, :check_now)
  end

  @doc """
  Re-check drift for specific resources to see if they are still drifting.

  ## Parameters
  - drifting_resources: Map of api_version_kind to list of {namespace, name} tuples

  ## Returns
  - {:ok, drift_percentage} - percentage of resources still drifting (0.0 to 1.0)
  - {:error, reason} - if there was an error
  """
  def recheck_drift(drifting_resources, server \\ __MODULE__) do
    GenServer.call(server, {:recheck_drift, drifting_resources}, 30_000)
  end

  @impl GenServer
  def handle_call(:check_now, _from, state) do
    Logger.info("Manual drift check triggered")

    case perform_drift_check(state) do
      {:ok, updated_state} ->
        {:reply, :ok, schedule_check(updated_state)}

      {:error, _reason} = error ->
        Logger.error("Manual drift check failed")
        {:reply, error, schedule_check(state)}
    end
  end

  @impl GenServer
  def handle_call({:recheck_drift, drifting_resources}, _from, state) do
    Logger.debug("Re-checking drift for resources")

    result = perform_recheck_drift(drifting_resources, state)
    {:reply, result, state}
  end

  @impl GenServer
  def handle_info(:perform_check, state) do
    Logger.debug("Performing scheduled drift check")

    updated_state =
      case perform_drift_check(state) do
        {:ok, new_state} ->
          new_state

        {:error, _reason} ->
          Logger.error("Scheduled drift check failed")
          state
      end

    {:noreply, schedule_check(updated_state)}
  end

  @impl GenServer
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # Private functions

  defp schedule_check(%State{check_interval: interval} = state) do
    # Cancel existing timer if present
    _cancelled = if state.timer_ref, do: Process.cancel_timer(state.timer_ref)

    timer_ref = Process.send_after(self(), :perform_check, interval)
    %{state | timer_ref: timer_ref}
  end

  defp perform_drift_check(%State{kube_state: kube_state} = state) do
    snapshot = kube_state.snapshot()

    with {:ok, drift_info} <- check_drift(snapshot, %{}, state),
         {:ok, updated_state} <- maybe_create_issue(drift_info, state) do
      {:ok, %{updated_state | last_check_time: DateTime.utc_now()}}
    end
  rescue
    error ->
      Logger.error("Snapshot failed: #{inspect(error)}")
      {:error, {:snapshot_failed, error}}
  end

  defp perform_recheck_drift(drifting_resources, %State{kube_state: kube_state} = state) do
    snapshot = kube_state.snapshot()

    with {:ok, drift_info} <- check_drift(snapshot, drifting_resources, state) do
      {:ok, drift_info.drift_percentage}
    end
  rescue
    error ->
      Logger.error("Snapshot failed during recheck: #{inspect(error)}")
      {:error, {:snapshot_failed, error}}
  end

  defp check_drift(snapshot, potential_drifting, %State{} = state) do
    # Step 1: Select resources to consider for each type
    to_consider = select_resources_to_consider(snapshot, potential_drifting, state)

    # Step 2: Check which of the considered resources are actually drifting
    verified_drifting = verify_drifting_resources(to_consider, state)

    # Step 3: Calculate drift statistics
    total_checked = count_total_resources(to_consider)
    total_drifted = count_total_resources(verified_drifting)

    drift_percentage = if total_checked > 0, do: total_drifted / total_checked, else: 0.0

    Logger.debug("Drift check completed")

    {:ok,
     %{
       drift_percentage: drift_percentage,
       total_checked: total_checked,
       total_drifted: total_drifted,
       drifting_resources: verified_drifting
     }}
  end

  defp select_resources_to_consider(snapshot, potential_drifting, %State{} = state) do
    snapshot
    |> Enum.map(fn {resource_type, resources} ->
      selected = select_resources_for_type(resource_type, resources, potential_drifting, state)
      {resource_type, selected}
    end)
    |> Enum.reject(fn {_, resources} -> Enum.empty?(resources) end)
    |> Map.new()
  end

  defp select_resources_for_type(resource_type, resources, potential_drifting, %State{} = state) do
    if Enum.empty?(potential_drifting) do
      sample_percentage = State.get_sample_percentage(state, resource_type)
      sample_resources(resources, sample_percentage)
    else
      potentially_drifting_for_type = Map.get(potential_drifting, resource_type, [])
      find_specific_resources(resources, potentially_drifting_for_type)
    end
  end

  defp find_specific_resources(resources, potentially_drifting_for_type) do
    potentially_drifting_for_type
    |> Enum.map(fn %{namespace: ns, name: n} ->
      Enum.find(resources, fn resource ->
        namespace(resource) == ns and name(resource) == n
      end)
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp verify_drifting_resources(to_consider, %State{} = state) do
    to_consider
    |> Map.new(fn {resource_type, resources} ->
      drifting_resources =
        resources
        |> Enum.filter(&resource_drifted?(&1, state))
        |> Enum.map(&extract_resource_identifier/1)

      {resource_type, drifting_resources}
    end)
    |> Enum.reject(fn {_, drifting} -> Enum.empty?(drifting) end)
    |> Map.new()
  end

  defp sample_resources(resources, percentage) when percentage >= 1.0, do: resources

  defp sample_resources(resources, percentage) do
    count = max(1, round(length(resources) * percentage))
    Enum.take_random(resources, count)
  end

  defp count_total_resources(resource_map) do
    resource_map
    |> Map.values()
    |> Enum.map(&length/1)
    |> Enum.sum()
  end

  defp resource_drifted?(resource, %State{client: client, connection: connection}) do
    {api_version, kind} = ApiVersionKind.from_resource_type!(ApiVersionKind.resource_type!(resource))
    resource_namespace = namespace(resource)
    resource_name = name(resource)

    operation = client.get(api_version, kind, namespace: resource_namespace, name: resource_name)

    case client.run(connection, operation) do
      {:ok, cluster_resource} ->
        # Compare hashes to detect drift
        snapshot_hash = Hashing.get_hash(resource)
        cluster_hash = Hashing.get_hash(cluster_resource)
        Hashing.different?(snapshot_hash, cluster_hash)

      {:error, %{status: 404}} ->
        # Resource exists in snapshot but not in cluster - this is drift
        true

      {:error, _reason} ->
        Logger.warning("Failed to fetch resource from cluster")
        false
    end
  rescue
    _e ->
      Logger.warning("Exception while checking resource drift")
      false
  end

  defp extract_resource_identifier(resource) do
    %{namespace: namespace(resource), name: name(resource)}
  end

  defp maybe_create_issue(
         %{drift_percentage: drift_percentage, drifting_resources: drifting_resources} = drift_info,
         %State{drift_threshold: threshold, issues_context: issues_context} = state
       ) do
    if drift_percentage > threshold and not Enum.empty?(drifting_resources) do
      Logger.warning("Drift threshold exceeded, creating stuck kubestate issue")

      case create_stuck_kubestate_issue(drift_info, issues_context) do
        {:ok, _issue} ->
          Logger.info("Created stuck kubestate issue")
          {:ok, state}

        {:error, reason} ->
          Logger.error("Failed to create stuck kubestate issue")
          {:error, {:issue_creation_failed, reason}}
      end
    else
      Logger.debug("Drift within acceptable threshold")

      {:ok, state}
    end
  end

  defp create_stuck_kubestate_issue(%{drifting_resources: drifting_resources} = drift_info, issues_context) do
    subject = "cluster.control_server.kube-state"

    # Convert drifting_resources maps to JSON-safe format with string keys
    json_safe_drifting_resources =
      Map.new(drifting_resources, fn {resource_type, identifiers} ->
        {resource_type,
         Enum.map(identifiers, fn %{namespace: namespace, name: name} ->
           %{"namespace" => namespace, "name" => name}
         end)}
      end)

    issues_context.create_issue(%{
      subject: subject,
      issue_type: :stuck_kubestate,
      trigger: :health_check,
      trigger_params: %{
        "drift_percentage" => drift_info.drift_percentage,
        "total_checked" => drift_info.total_checked,
        "total_drifted" => drift_info.total_drifted,
        "drifting_resources" => json_safe_drifting_resources,
        "detector" => "stuck_detector",
        "check_time" => DateTime.to_iso8601(DateTime.utc_now())
      },
      status: :detected
    })
  end
end
