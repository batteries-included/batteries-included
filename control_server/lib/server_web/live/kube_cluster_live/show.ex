defmodule ServerWeb.KubeClusterLive.Show do
  use ServerWeb, :live_view

  alias Server.Clusters

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:kube_cluster, Clusters.get_kube_cluster!(id))}
  end

  defp page_title(:show), do: "Show Kube cluster"
  defp page_title(:edit), do: "Edit Kube cluster"
end
