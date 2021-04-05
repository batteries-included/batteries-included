defmodule ServerWeb.ServicesLive.Monitoring do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ServerWeb, :live_view
  use Timex

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, 5000)
    {:ok, socket |> assign(:pods, get_pods())}
  end

  def summarize_pod(pod) do
    restartCount =
      pod["status"]["containerStatuses"]
      |> Enum.map(fn cs -> cs["restartCount"] end)
      |> Enum.sum()

    {:ok, startTime} = pod["status"]["startTime"] |> Timex.parse("{ISO:Extended}")

    fromStart = Timex.from_now(startTime)

    pod |> Map.put("summary", %{"restartCount" => restartCount, "fromStart" => fromStart})
  end

  defp get_pods do
    pods = Server.Services.MonitoringPods.get()
    pods |> Enum.map(&summarize_pod/1)
  end

  @impl true
  def handle_info(:update, socket) do
    Process.send_after(self(), :update, 5000)
    {:noreply, socket |> assign(:pods, get_pods())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
  end
end
