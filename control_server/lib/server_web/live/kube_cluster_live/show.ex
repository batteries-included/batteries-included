defmodule ServerWeb.KubeClusterLive.Show do
  @moduledoc """
  Show a KubeCluster.
  This is the cluter home page essentially.
  """
  use ServerWeb, :live_view
  require Logger

  alias Server.Clusters
  alias Server.Configs.Adoption
  alias Server.Configs.RunningSet

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
     |> assign(:adoption_config, Adoption.for_kube_cluster!(id))
     |> assign(:running_config, RunningSet.for_kube_cluster!(id))}
  end

  @impl true
  def handle_event("adopt_cluster", _value, socket) do
    {:ok, new_config} = Adoption.adopt(socket.assigns.adoption_config)
    {:noreply, assign(socket, :adoption_config, new_config)}
  end

  @impl true
  def handle_event("start_service", %{"service" => service_name}, socket) do
    {:ok, new_config} =
      socket.assigns.running_config
      |> RunningSet.set_running(service_name)

    {:noreply, assign(socket, :running_config, new_config)}
  end

  @impl true
  def handle_event("stop_service", %{"service" => service_name}, socket) do
    {:ok, new_config} =
      socket.assigns.running_config
      |> RunningSet.set_running(service_name, false)

    {:noreply, assign(socket, :running_config, new_config)}
  end

  defp page_title(:show), do: "Show Kube cluster"
  defp page_title(:edit), do: "Edit Kube cluster"
end
