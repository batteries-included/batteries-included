defmodule KubeBootstrap.ControlServer do
  @moduledoc false

  alias CommonCore.Resources.FieldAccessors

  require Logger

  def wait_for_control_server(conn, summary) do
    namespace = CommonCore.StateSummary.Namespaces.core_namespace(summary)

    with :ok <- wait_for_deployment(conn, namespace),
         :ok <- wait_for_one_pod(conn, namespace) do
      Logger.info("Control Server is ready")
      :ok
    else
      {:error, reason} ->
        Logger.error("Control Server failed to start", reason: reason)
        {:error, reason}
    end
  end

  defp wait_for_deployment(conn, namespace) do
    Logger.info("Waiting for Control Server to be ready in namespace #{namespace}")

    deployment_operation =
      "apps/v1"
      |> K8s.Client.list(:deployment, namespace: namespace)
      |> K8s.Selector.label(%{
        "battery/app" => "battery-control-server"
      })

    case K8s.Client.wait_until(conn, deployment_operation,
           find: fn
             %{"items" => items} ->
               two_or_more_generations =
                 Enum.filter(items, fn item ->
                   observed_generation =
                     item
                     |> FieldAccessors.status()
                     |> Map.get("observedGeneration", 0)

                   # When the deployment is first ready it will
                   # change it's own spec causing the generation to increment
                   # We want to wait for that to happen at least once
                   observed_generation >= 2
                 end)

               !Enum.empty?(two_or_more_generations)

             _ ->
               false
           end,
           eval: true,
           timeout: 300
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
           timeout: 300
         ) do
      {:ok, _} ->
        :ok

      {:error, _reason} ->
        {:error, :timeout}
    end
  end
end
