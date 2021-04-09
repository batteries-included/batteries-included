defmodule ServerWeb.ServicesLive.Monitoring do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ServerWeb, :live_view
  use Timex

  require Logger

  alias Server.Services.MonitoringPods
  alias Server.Configs.RunningSet

  @pod_update_time 5000

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, @pod_update_time)
    {:ok, socket |> assign(:pods, get_pods()) |> assign(:running, get_running())}
  end

  def summarize_pod(pod) do
    restart_count =
      pod["status"]["containerStatuses"]
      |> Enum.map(fn cs -> cs["restartCount"] end)
      |> Enum.sum()

    {:ok, start_time} = pod["status"]["startTime"] |> Timex.parse("{ISO:Extended}")

    from_start = Timex.from_now(start_time)

    pod |> Map.put("summary", %{"restartCount" => restart_count, "fromStart" => from_start})
  end

  defp get_pods do
    MonitoringPods.get() |> Enum.map(&summarize_pod/1)
  end

  defp get_running do
    RunningSet.get!().content |> Map.get("monitoring")
  end

  @impl true
  def handle_info(:update, socket) do
    Process.send_after(self(), :update, @pod_update_time)
    {:noreply, socket |> assign(:pods, get_pods())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
  end

  @impl true
  def handle_event("start_service", %{}, socket) do
    with {:ok, new_config} <- RunningSet.set_running(RunningSet.get!(), "monitoring", true) do
      new_config.content |> inspect() |> Logger.info()
      {:noreply, assign(socket, :running, true)}
    end
  end
end
