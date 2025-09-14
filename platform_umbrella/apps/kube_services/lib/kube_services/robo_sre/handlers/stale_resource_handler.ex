defmodule KubeServices.RoboSRE.StaleResourceHandler do
  @moduledoc """
  Handler for remediating stale resource issues.

  This handler:
  1. Deletes the stale resource from the cluster
  2. Stores the resource in the deleted resource table for potential recovery
  3. Monitors the deletion to ensure it was successful
  """

  @behaviour KubeServices.RoboSRE.Handler

  use GenServer
  use TypedStruct

  alias CommonCore.RoboSRE.Issue
  alias CommonCore.RoboSRE.RemediationPlan
  alias KubeServices.KubeState
  alias KubeServices.RoboSRE.Handler
  alias KubeServices.Stale

  require Logger

  @state_opts [:kube_state, :stale]
  @me __MODULE__

  typedstruct module: State do
    field :kube_state, module(), default: KubeState
    field :stale, module(), default: Stale
  end

  def start_link(opts \\ []) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    {init_opts, opts} = Keyword.split(opts, @state_opts)

    GenServer.start_link(__MODULE__, init_opts, opts)
  end

  @impl GenServer
  def init(opts) do
    kube_state = Keyword.get(opts, :kube_state, KubeState)
    stale = Keyword.get(opts, :stale, Stale)

    state = %State{kube_state: kube_state, stale: stale}

    {:ok, state}
  end

  @impl Handler
  @spec preflight(Issue.t()) :: {:ok, :ready | :skip} | {:error, any()}
  def preflight(%Issue{} = issue) do
    GenServer.call(@me, {:preflight, issue})
  end

  @impl Handler
  @spec plan(Issue.t()) :: {:ok, RemediationPlan.t()} | {:error, String.t()}
  def plan(%Issue{} = issue) do
    GenServer.call(@me, {:plan, issue})
  end

  @impl Handler
  @spec verify(Issue.t()) :: {:ok, :resolved} | {:ok, :pending} | {:error, String.t()}
  def verify(%Issue{} = issue) do
    GenServer.call(@me, {:verify, issue})
  end

  @impl GenServer
  def handle_call(
        {:preflight, %Issue{trigger_params: params} = issue},
        _from,
        %State{kube_state: kube_state, stale: stale} = state
      ) do
    Logger.info(
      "Preflight check for stale resource issue (issue_id: #{issue.id}, subject: #{issue.subject} params: #{inspect(params)})"
    )

    {api_version_kind, namespace, name} = destructure_params(issue)
    # We have to get the resource again to since we only pass the identifying info in trigger_params
    # and we need the labels and annotations as they currently exist on the resource
    result =
      with {:ok, resource} <- kube_state.get(api_version_kind, namespace, name),
           true <- stale.stale?(resource) do
        {:ok, :ready}
      else
        :missing ->
          {:ok, :skip}

        false ->
          {:error, :not_stale}
      end

    {:reply, result, state}
  end

  @impl GenServer
  def handle_call({:plan, %Issue{issue_type: :stale_resource} = issue}, _from, state) do
    Logger.debug("Planning remediation for stale resource (issue_id: #{issue.id}, subject: #{issue.subject})")

    {api_version_kind, namespace, name} = destructure_params(issue)

    plan =
      RemediationPlan.delete_resource(
        api_version_kind,
        namespace,
        name
      )

    {:reply, {:ok, plan}, state}
  end

  @impl GenServer
  def handle_call({:plan, issue}, _from, state) do
    # This is mostly a hack to make dialyzer happy
    Logger.error("Planning remediation for unknown issue type (issue_id: #{issue.id}, subject: #{issue.subject})")
    {:reply, {:error, "Unknown issue type"}, state}
  end

  @impl GenServer
  def handle_call({:verify, %Issue{issue_type: :stale_resource} = issue}, _from, %State{kube_state: kube_state} = state) do
    Logger.debug("Verifying stale resource deletion success (issue_id: #{issue.id})")

    {api_version_kind, namespace, name} = destructure_params(issue)

    result =
      case kube_state.get(api_version_kind, namespace, name) do
        {:ok, _resource} ->
          {:ok, :pending}

        :missing ->
          {:ok, :resolved}
      end

    {:reply, result, state}
  end

  @impl GenServer
  def handle_call({:verify, issue}, _from, state) do
    # This is mostly a hack to make dialyzer happy
    Logger.error("Verifying remediation for unknown issue type (issue_id: #{issue.id}, subject: #{issue.subject})")
    {:reply, {:error, "Unknown issue type"}, state}
  end

  defp destructure_params(%Issue{trigger_params: params, subject: subject}) do
    api_version_kind =
      params
      |> Map.get("api_version_kind", Map.get(params, :api_version_kind))
      |> to_atom()

    {namespace, name} = parse_subject_for_resource(subject)

    {api_version_kind, namespace, name}
  end

  defp to_atom(string) when is_binary(string) do
    String.to_atom(string)
  end

  defp to_atom(atom) when is_atom(atom), do: atom

  # Parse the subject to extract namespace and name
  # Subject format for stale resources: "namespace.name" or just "name" (for cluster-scoped resources)
  defp parse_subject_for_resource(subject) do
    case String.split(subject, ":") do
      [name] ->
        # Cluster-scoped resource (no namespace)
        {nil, name}

      [namespace, name] ->
        # Namespaced resource
        {namespace, name}

      _ ->
        Logger.error("Invalid subject format for stale resource: #{subject}")
        {nil, subject}
    end
  end
end
