defmodule KubeBootstrap.MetalLB do
  @moduledoc false

  alias CommonCore.Resources.FieldAccessors

  def wait_for_metallb(conn, summary) do
    # If metallb is not installed, then just return ok
    if CommonCore.StateSummary.Batteries.batteries_installed?(summary, :metallb) do
      namespace = CommonCore.StateSummary.Namespaces.base_namespace(summary)

      wait_for_pods(conn, namespace)
    else
      :ok
    end
  end

  defp wait_for_pods(conn, namespace) do
    pod_operation =
      "v1"
      |> K8s.Client.list("Pod", namespace: namespace)
      |> K8s.Selector.label(%{"battery/app" => "metallb"})
      |> K8s.Selector.field({"status.phase", "Running"})

    case K8s.Client.wait_until(conn, pod_operation,
           find: fn
             %{"items" => items} when is_list(items) ->
               all_containers_running =
                 Enum.filter(items, fn item ->
                   containers =
                     item
                     |> FieldAccessors.status()
                     |> Map.get("containerStatuses", [])

                   Enum.all?(containers, fn c -> c["ready"] == true end)
                 end)

               !Enum.empty?(all_containers_running)

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
