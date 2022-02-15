defmodule ControlServer.Services.Pods do
  @moduledoc """
  Get all the pods running for the services.
  """

  @namespace "battery-core"
  @client K8s.Client

  def get(namespace \\ @namespace) do
    operation = @client.list("v1", :pods, namespace: namespace)

    with {:ok, res} <- @client.run(KubeExt.ConnectionPool.get(:default), operation) do
      KubeExt.Resource.items(res)
    end
  end

  def summarize(nil) do
  end

  def summarize(pod) do
    Map.put(pod, "summary", %{
      "restartCount" => get_restart_count(pod),
      "fromStart" => get_from_start(pod)
    })
  end

  defp get_restart_count(pod) do
    pod
    |> Map.get("status", %{})
    |> Map.get("containerStatuses", [])
    |> Enum.filter(fn cs -> cs != nil end)
    |> Enum.map(fn cs -> Map.get(cs, "restartCount", 0) end)
    |> Enum.sum()
  end

  defp get_from_start(pod) do
    case pod
         |> Map.get("status", %{})
         |> Map.get("startTime", "")
         |> Timex.parse("{ISO:Extended}") do
      {:ok, start_time} ->
        Timex.from_now(start_time)

      _ ->
        "Unknown"
    end
  end
end
