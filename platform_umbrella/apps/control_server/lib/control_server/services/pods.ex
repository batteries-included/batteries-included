defmodule ControlServer.Services.Pods do
  @moduledoc """
  Get all the pods running for the services.
  """

  @namespace "battery-core"

  def get do
    with {:ok, res} <-
           "v1"
           |> K8s.Client.list(:pods, namespace: @namespace)
           |> K8s.Client.run(:default) do
      Map.get(res, "items", [])
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
