defmodule ControlServer.Services.Pods do
  @moduledoc """
  Get all the pods running for the services.
  """

  @monitoring_ns "battery-monitoring"
  @database_ns "battery-db"
  @security_ns "battery-security"
  @devtools_ns "battery-devtools"

  def get(:monitoring), do: get(@monitoring_ns)
  def get(:postgres), do: get(@database_ns)
  def get(:security), do: get(@security_ns)
  def get(:devtools), do: get(@devtools_ns)

  def get(namespace) do
    with {:ok, res} <-
           K8s.Client.list("v1", :pods, namespace: namespace)
           |> K8s.Client.run(Bonny.Config.cluster_name()) do
      Map.get(res, "items", [])
    end
  end

  def summarize(nil) do
  end

  def summarize(pod) do
    pod
    |> Map.put("summary", %{
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
