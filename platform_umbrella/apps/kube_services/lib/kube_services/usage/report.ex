defmodule KubeServices.Usage.Report do
  alias ControlServer.Usage
  alias K8s.Resource

  require Logger

  defstruct [:generated_at, :pod_report, :node_report, num_nodes: 0, num_pods: 0]

  def new do
    Logger.debug("Starting report")

    with {:ok, pod_report} <- report_pods(),
         {:ok, node_report} <- report_nodes() do
      {:ok,
       %__MODULE__{
         generated_at: DateTime.utc_now(),
         pod_report: pod_report,
         node_report: node_report,
         num_pods: num_pods(pod_report),
         num_nodes: num_nodes(node_report)
       }}
    end
  end

  def to_db(report) do
    report |> Map.drop([:generated_at]) |> Map.from_struct() |> Usage.create_usage_report()
  end

  def report_pods do
    {:ok,
     KubeState.pods()
     |> Enum.filter(fn p -> p |> Resource.namespace() |> String.starts_with?("battery") end)
     |> Enum.map(&sanitize_pod/1)
     |> Enum.group_by(&Resource.namespace/1)}
  end

  def report_nodes do
    {:ok,
     KubeState.nodes()
     |> Enum.map(&sanitize_node/1)
     |> Enum.with_index()
     |> Enum.map(fn {node, index} ->
       name = Resource.name(node) || "unknown-node-#{index}"
       {name, node}
     end)
     |> Map.new()}
  end

  def battery_namespace?(ns) do
    String.starts_with?(Resource.name(ns), "battery")
  end

  def sanitize_pod(%{} = pod) do
    pod
    |> update_in(["metadata"], fn metadata ->
      Map.drop(metadata, ["managedFields", "ownerReferences", "annotations", "finalizers"])
    end)
    |> Map.drop(["spec"])
  end

  def sanitize_pod([] = _arg), do: %{}

  def sanitize_node(%{} = node) do
    node
    |> update_in(["status"], fn status -> Map.drop(status, ["images", "daemonEndpoints"]) end)
    |> update_in(["metadata"], fn metadata ->
      Map.drop(metadata, ["managedFields", "annotations", "finalizers"])
    end)
  end

  def sanitize_node([] = _arg), do: %{}

  def num_nodes(node_report) do
    map_size(node_report)
  end

  def num_pods(pod_report) do
    pod_report
    |> Map.values()
    |> Enum.map(&length/1)
    |> Enum.reduce(0, fn x, acc -> x + acc end)
  end
end
