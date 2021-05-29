defmodule ControlServer.Usage.KubeUsage do
  @moduledoc """
  Module to get and compute the node usage of the platform.
  """
  alias K8s.Client

  require Logger

  def report_namespaces do
    with {:ok, %{"items" => namespaces}} <- list_all_namespace() do
      battery_namespaces = Enum.filter(namespaces, &battery_namespace?/1)

      pods =
        Enum.map(battery_namespaces, fn %{"metadata" => %{"name" => ns_name}} = _ns ->
          {ns_name, ns_name |> list_namespace_pods() |> Enum.map(&sanitize_pod/1)}
        end)

      {:ok, Map.new(pods)}
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
    String.starts_with?(name, "battery")
  end

  defp battery_namespace?(_), do: false

  def list_all_namespace, do: "v1" |> Client.list("Namespace") |> Client.run(:default)
  def list_all_nodes, do: "v1" |> Client.list("Node") |> Client.run(:default)

  def list_namespace_pods(%{"metadata" => %{"name" => ns_name}} = _ns),
    do: list_namespace_pods(ns_name)

  def list_namespace_pods(ns_name) when is_binary(ns_name) do
    with {:ok, %{"items" => items}} <-
           "v1" |> Client.list("Pod", namespace: ns_name) |> Client.run(:default) do
      items
    end
  end

  def list_namespace_pods(_), do: []

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
end
