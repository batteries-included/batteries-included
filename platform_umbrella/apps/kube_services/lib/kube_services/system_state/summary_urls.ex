defmodule KubeServices.SystemState.SummaryURLs do
  @moduledoc """
  This GenServer watches for the new system state summaries then caches some
  computed properties. These are then made available to the front end without
  having to compute a full system state snapshot.
  """

  use GenServer
  use TypedStruct

  alias CommonCore.Resources.FieldAccessors
  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.PostgresState
  alias CommonCore.StateSummary.URLs
  alias EventCenter.SystemStateSummary
  alias KubeServices.SystemState.Summarizer

  require Logger

  typedstruct module: State do
    field :summary, StateSummary.t(), default: nil, enforce: false
    field :subscribe, boolean(), default: true, enforce: false
  end

  @me __MODULE__

  def start_link(opts) do
    {state_opts, genserver_opts} =
      opts |> Keyword.put_new(:name, @me) |> Keyword.split([:summary])

    GenServer.start_link(@me, state_opts, genserver_opts)
  end

  @impl GenServer
  def init(opts) do
    Logger.debug("Starting SummaryURLs")

    opts = Keyword.put_new_lazy(opts, :summary, &Summarizer.cached/0)
    state = struct(State, opts)

    if state.subscribe, do: :ok = SystemStateSummary.subscribe()

    {:ok, state}
  end

  @impl GenServer
  def handle_info(%StateSummary{} = message, state) do
    new_state = %{state | summary: message}
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_call({:project_dashboard_url, %{} = project}, _from, %{summary: summary} = state) do
    query = URI.encode_query(%{"var-project-id" => project.id})

    url =
      summary
      |> URLs.project_dashboard()
      |> URI.append_query(query)
      |> URI.to_string()

    {:reply, url, state}
  end

  # For a given postgres cluster, return the URL to the cloud native pg dashboard in grafana
  @impl GenServer
  def handle_call({:pg_dashboard_url, %{} = cluster}, _from, %{summary: summary} = state) do
    namespace = PostgresState.cluster_namespace(summary, cluster)

    query =
      URI.encode_query(%{"var-cluster" => "pg-" <> cluster.name, "var-namespace" => namespace})

    url =
      summary
      |> URLs.cloud_native_pg_dashboard()
      |> URI.append_query(query)
      |> URI.to_string()

    {:reply, url, state}
  end

  def handle_call({:pod_dashboard_url, %{} = pod}, _from, %{summary: summary} = state) do
    query =
      URI.encode_query(%{
        "var-namespace" => FieldAccessors.namespace(pod),
        "var-pod" => FieldAccessors.name(pod)
      })

    url =
      summary
      |> URLs.pod_dashboard()
      |> URI.append_query(query)
      |> URI.to_string()

    {:reply, url, state}
  end

  def handle_call({:node_dashboard_url, %{} = node}, _from, %{summary: summary} = state) do
    query =
      URI.encode_query(%{
        "var-node" => FieldAccessors.name(node)
      })

    url =
      summary
      |> URLs.node_dashboard()
      |> URI.append_query(query)
      |> URI.to_string()

    {:reply, url, state}
  end

  def handle_call({:knative_service_url, %{} = service}, _from, %{summary: summary} = state) do
    url =
      summary
      |> URLs.knative_url(service)
      |> URI.to_string()

    {:reply, url, state}
  end

  def handle_call([method | args], _from, %{summary: summary} = state) do
    {:reply, apply(URLs, method, [summary | args]), state}
  end

  @spec url_for_battery(atom | pid | {atom, any} | {:via, atom, any}, atom()) :: String.t() | nil
  def url_for_battery(target \\ @me, battery) do
    result = GenServer.call(target, [:uri_for_battery, battery])
    URI.to_string(result)
  end

  @spec keycloak_url_for_realm(atom | pid | {atom, any} | {:via, atom, any}, String.t()) ::
          String.t() | nil
  def keycloak_url_for_realm(target \\ @me, realm) do
    result = GenServer.call(target, [:keycloak_uri_for_realm, realm])
    URI.to_string(result)
  end

  @spec keycloak_console_url_for_realm(atom | pid | {atom, any} | {:via, atom, any}, String.t()) ::
          String.t() | nil
  def keycloak_console_url_for_realm(target \\ @me, realm) do
    result = GenServer.call(target, [:keycloak_console_uri_for_realm, realm])
    URI.to_string(result)
  end

  def project_dashboard_url(target \\ @me, project) do
    GenServer.call(target, {:project_dashboard_url, project})
  end

  def pg_dashboard_url(target \\ @me, cluster) do
    GenServer.call(target, {:pg_dashboard_url, cluster})
  end

  def pod_dashboard_url(target \\ @me, pod_resource) do
    GenServer.call(target, {:pod_dashboard_url, pod_resource})
  end

  def node_dashboard_url(target \\ @me, node_resource) do
    GenServer.call(target, {:node_dashboard_url, node_resource})
  end

  def knative_service_url(target \\ @me, service) do
    GenServer.call(target, {:knative_service_url, service})
  end
end
