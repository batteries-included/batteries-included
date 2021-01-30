defmodule ServerWeb.KubeClusterLive.Show do
  use ServerWeb, :live_view
  require Logger

  alias Server.Clusters
  alias Server.Configs
  alias Server.Configs.Adoption

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:kube_cluster, Clusters.get_kube_cluster!(id))
     |> assign(:adoption_config, Adoption.for_kube_cluster!(id))}
  end

  @impl true
  def handle_event("adopt_cluster", _value, socket) do
    {:ok, new_config} = Adoption.adopt(socket.assigns.adoption_config)

    # Updating json content seems to return
    {:noreply, assign(socket, :adoption_config, new_config)}
  end

  defp page_title(:show), do: "Show Kube cluster"
  defp page_title(:edit), do: "Edit Kube cluster"
end
