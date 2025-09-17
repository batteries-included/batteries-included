defmodule KubeBootstrap.ControlServer do
  @moduledoc false

  def wait_for_control_server(conn, summary) do
    namespace = CommonCore.StateSummary.Namespaces.core_namespace(summary)

    pod_operation =
      "v1"
      |> K8s.Client.list(:pod, namespace: namespace)
      |> K8s.Selector.label(%{
        "battery/app" => "battery-control-server"
      })
      |> K8s.Selector.field({"status.phase", "Running"})

    case K8s.Client.wait_until(conn, pod_operation,
           find: fn
             %{"items" => items} ->
               !Enum.empty?(items)

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
