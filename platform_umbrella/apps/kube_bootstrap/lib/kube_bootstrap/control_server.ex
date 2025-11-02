defmodule KubeBootstrap.ControlServer do
  @moduledoc false

  alias CommonCore.Resources.FieldAccessors

  require Logger

  def wait_for_control_server(conn, summary) do
    namespace = CommonCore.StateSummary.Namespaces.core_namespace(summary)

    with :ok <- wait_for_stateful_set(conn, namespace),
         :ok <- wait_for_one_pod(conn, namespace),
         :ok <- wait_for_one_endpoint(conn, namespace) do
      Logger.info("Control Server is ready")
      :ok
    else
      {:error, reason} ->
        Logger.error("Control Server failed to start", reason: reason)
        {:error, reason}
    end
  end

  defp wait_for_stateful_set(conn, namespace) do
    Logger.info("Waiting for Control Server statefulset to be ready in namespace #{namespace}")

    stateful_set_operation = K8s.Client.get("apps/v1", "StatefulSet", namespace: namespace, name: "controlserver")

    case K8s.Client.wait_until(conn, stateful_set_operation,
           find: fn
             %{} = item ->
               observed_generation =
                 item
                 |> FieldAccessors.status()
                 |> Map.get("observedGeneration", 0)

               # When the deployment is first ready it will
               # change it's own spec causing the generation to increment
               # We want to wait for that to happen at least once
               observed_generation >= 2

             _ ->
               false
           end,
           eval: true,
           timeout: 600
         ) do
      {:ok, _} ->
        :ok

      {:error, _reason} ->
        {:error, :timeout}
    end
  end

  defp wait_for_one_pod(conn, namespace) do
    Logger.info("Waiting for single Control Server pod to be running in namespace #{namespace}")

    pod_operation =
      "v1"
      |> K8s.Client.list(:pod, namespace: namespace)
      |> K8s.Selector.label(%{
        "battery/app" => "battery-control-server"
      })

    case K8s.Client.wait_until(conn, pod_operation,
           find: fn
             %{"items" => items} ->
               Enum.count(items) == 1

             _ ->
               false
           end,
           eval: true,
           timeout: 600
         ) do
      {:ok, _} ->
        :ok

      {:error, _reason} ->
        {:error, :timeout}
    end
  end

  defp wait_for_one_endpoint(conn, namespace) do
    Logger.info("Waiting for single Control Server endpoint to be ready in namespace #{namespace}")

    endpoint_operation =
      "v1"
      |> K8s.Client.list(:endpoints, namespace: namespace)
      |> K8s.Selector.label(%{
        "battery/app" => "battery-control-server"
      })

    case K8s.Client.wait_until(conn, endpoint_operation,
           find: fn
             %{"items" => items} ->
               Logger.info("Found #{Enum.count(items)} endpoint(s) for control server")
               # We should find a single endpoint
               # with a single subset
               # with a single address
               Enum.count(items, fn item ->
                 subsets = Map.get(item, "subsets", [])

                 Enum.count(subsets, fn subset ->
                   addresses = Map.get(subset, "addresses", [])
                   Enum.count(addresses) == 1
                 end) == 1
               end) == 1

             _ ->
               false
           end,
           eval: true,
           timeout: 600
         ) do
      {:ok, _} ->
        :ok

      {:error, _reason} ->
        {:error, :timeout}
    end
  end
end
