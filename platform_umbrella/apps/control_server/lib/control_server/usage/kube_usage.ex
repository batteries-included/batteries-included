defmodule ControlServer.Usage.KubeUsage do
  @moduledoc """
  Module to get and compute the node usage of the platform.
  """
  require Logger

  def report_namespaces do
    with {:ok, %{"items" => namespaces}} <- list_all_namespace() do
      battery_namespaces =
        namespaces
        |> Enum.filter(&battery_namespace?/1)

      pods = battery_namespaces |> Enum.flat_map(&list_namespace_pods/1)

      node_names = pods |> Enum.map(fn pod -> get_in(pod, ["spec", "nodeName"]) end)

      {:ok,
       Enum.zip(pods, node_names)
       |> Enum.group_by(fn {_, nn} -> nn end, fn {pod, _} -> sanitize_pod(pod) end)}
    end
  end

  def report_nodes do
    with {:ok, %{"items" => nodes}} <- list_all_nodes() do
      node_report =
        nodes
        |> Enum.map(&sanitize_node/1)
        |> Enum.with_index()
        |> Enum.map(fn {node, index} ->
          name = get_in(node, ["metadata", "name"]) || "unknown-node-#{index}"
          {name, node}
        end)
        |> Map.new()

      {:ok, node_report}
    end
  end

  defp battery_namespace?(%{"metadata" => %{"name" => name}} = _ns) do
    name |> String.starts_with?("battery")
  end

  defp battery_namespace?(_), do: false

  def list_all_namespace, do: K8s.Client.list("v1", "Namespace") |> K8s.Client.run(:default)
  def list_all_nodes, do: K8s.Client.list("v1", "Node") |> K8s.Client.run(:default)

  def list_namespace_pods(%{"metadata" => %{"name" => ns_name}} = _ns) do
    with {:ok, %{"items" => items}} <-
           K8s.Client.list("v1", "Pod", namespace: ns_name) |> K8s.Client.run(:default) do
      items
    end
  end

  def list_namespace_pods(_), do: []

  def sanitize_pod(%{} = pod) do
    pod
    |> Map.drop(["status"])
  end

  def sanitize_pod([] = _arg), do: %{}

  def sanitize_node(%{} = node) do
    node
    |> update_in(["status"], fn status -> status |> Map.drop(["images"]) end)
    |> update_in(["metadata"], fn metadata -> metadata |> Map.delete("managedFields") end)
  end

  def sanitize_node([] = _arg), do: %{}
end
