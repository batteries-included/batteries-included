defmodule ServerWeb.KubeClusterLive.FormComponent do
  use ServerWeb, :live_component

  alias Server.Clusters

  @impl true
  def update(%{kube_cluster: kube_cluster} = assigns, socket) do
    changeset = Clusters.change_kube_cluster(kube_cluster)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"kube_cluster" => kube_cluster_params}, socket) do
    changeset =
      socket.assigns.kube_cluster
      |> Clusters.change_kube_cluster(kube_cluster_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"kube_cluster" => kube_cluster_params}, socket) do
    save_kube_cluster(socket, socket.assigns.action, kube_cluster_params)
  end

  defp save_kube_cluster(socket, :edit, kube_cluster_params) do
    case Clusters.update_kube_cluster(socket.assigns.kube_cluster, kube_cluster_params) do
      {:ok, _kube_cluster} ->
        {:noreply,
         socket
         |> put_flash(:info, "Kube cluster updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_kube_cluster(socket, :new, kube_cluster_params) do
    case Clusters.create_kube_cluster(kube_cluster_params) do
      {:ok, _kube_cluster} ->
        {:noreply,
         socket
         |> put_flash(:info, "Kube cluster created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
