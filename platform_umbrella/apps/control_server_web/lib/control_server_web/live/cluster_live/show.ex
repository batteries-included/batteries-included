defmodule ControlServerWeb.ClusterLive.Show do
  @moduledoc """
  The Postgres Clusters show a single live view.
  """
  use ControlServerWeb, :live_view

  alias ControlServer.Postgres

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:cluster, Postgres.get_cluster!(id))}
  end

  defp page_title(:show), do: "Show Cluster"
  defp page_title(:edit), do: "Edit Cluster"
end
