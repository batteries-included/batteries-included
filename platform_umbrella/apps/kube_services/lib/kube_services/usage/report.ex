defmodule KubeServices.Usage.Report do
  import K8s.Resource.FieldAccessors

  alias ControlServer.Usage
  alias KubeExt.KubeState

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
     |> Enum.filter(fn p -> p |> namespace() |> String.starts_with?("battery") end)
     |> Enum.group_by(&namespace/1)
     |> Enum.map(fn {namespace, pods} -> {namespace, length(pods)} end)
     |> Enum.into(%{})}
  end

  def report_nodes do
    {:ok,
     KubeState.nodes()
     |> Enum.map(&sanitize_node/1)
     |> Enum.with_index()
     |> Enum.map(fn {node, index} ->
       name = name(node) || "unknown-node-#{index}"
       {name, node}
     end)
     |> Map.new()}
  end

  def battery_namespace?(ns) do
    String.starts_with?(name(ns), "battery")
  end

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
    |> Enum.reduce(0, fn x, acc -> x + acc end)
  end
end
