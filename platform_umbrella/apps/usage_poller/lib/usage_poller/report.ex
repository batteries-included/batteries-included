defmodule UsagePoller.Report do
  alias K8s.Client
  alias KubeExt.ConnectionPool

  require Logger

  defstruct [:namespace_report, :node_report, num_nodes: 0, num_pods: 0]

  def new do
    Logger.debug("Starting report")

    with {:ok, namespace_report} <- report_namespaces(),
         {:ok, node_report} <- report_nodes() do
      {:ok,
       %__MODULE__{
         namespace_report: namespace_report,
         node_report: node_report,
         num_pods: num_pods(namespace_report),
         num_nodes: num_nodes(node_report)
       }}
    end
  end

  def report_namespaces do
    with {:ok, battery_namespaces} <- battery_namespaces() do
      {:ok,
       battery_namespaces
       |> Enum.map(fn ns_resouce ->
         # From the full object extract the name and use
         # that to list all pods in that namespace.
         #
         # Then remove the un-needed stuff.
         pod_name = K8s.Resource.name(ns_resouce)

         with {:ok, ns_pods} <- namespace_pods(pod_name) do
           {pod_name, Enum.map(ns_pods, &sanitize_pod/1)}
         end
       end)
       |> Map.new()}
    end
  end

  def report_nodes do
    with {:ok, nodes} <- all_nodes() do
      {:ok,
       nodes
       |> Enum.map(&sanitize_node/1)
       |> Enum.with_index()
       |> Enum.map(fn {node, index} ->
         name = K8s.Resource.name(node) || "unknown-node-#{index}"
         {name, node}
       end)
       |> Map.new()}
    end
  end

  def battery_namespace?(ns) do
    String.starts_with?(K8s.Resource.name(ns), "battery")
  end

  def all_namespaces do
    op = Client.list("v1", "Namespace")

    with {:ok, ns_list} <- Client.run(ConnectionPool.get(), op) do
      Logger.debug("List all namespace => #{inspect(ns_list)}")
      {:ok, KubeExt.Resource.items(ns_list)}
    end
  end

  def battery_namespaces do
    with {:ok, ns_list} <- all_namespaces() do
      {:ok, Enum.filter(ns_list, &battery_namespace?/1)}
    end
  end

  def all_nodes do
    op = Client.list("v1", "Node")

    with {:ok, node_list} <- Client.run(ConnectionPool.get(), op) do
      {:ok, KubeExt.Resource.items(node_list)}
    end
  end

  def namespace_pods(ns_name) when is_binary(ns_name) do
    operation = Client.list("v1", "Pod", namespace: ns_name)
    conn = ConnectionPool.get()

    with {:ok, pod_list} <- Client.run(conn, operation) do
      Logger.debug("Got result for ns=#{ns_name}")
      {:ok, KubeExt.Resource.items(pod_list)}
    end
  end

  def namespace_pods(ns),
    do: namespace_pods(K8s.Resource.name(ns))

  def sanitize_pod(%{} = pod) do
    update_in(pod, ["metadata"], fn metadata -> Map.drop(metadata, ["managedFields"]) end)
  end

  def sanitize_pod([] = _arg), do: %{}

  def sanitize_node(%{} = node) do
    node
    |> update_in(["status"], fn status -> Map.drop(status, ["images"]) end)
    |> update_in(["metadata"], fn metadata -> Map.delete(metadata, "managedFields") end)
  end

  def sanitize_node([] = _arg), do: %{}

  def num_nodes(node_report) do
    map_size(node_report)
  end

  def num_pods(namespace_report) do
    namespace_report
    |> Map.values()
    |> Enum.map(&length/1)
    |> Enum.reduce(0, fn x, acc -> x + acc end)
  end
end
