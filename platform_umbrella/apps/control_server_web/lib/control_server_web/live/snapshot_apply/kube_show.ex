defmodule ControlServerWeb.Live.KubeSnapshotShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.ResourcePathsTable

  alias ControlServer.SnapshotApply.Kube

  require Logger

  @impl Phoenix.LiveView
  def mount(%{"id" => id, "umbrella_id" => uid} = _params, _session, socket) do
    {:ok, socket |> assign_snapshot(id) |> assign_umbrella_id(uid)}
  end

  defp assign_snapshot(socket, id) do
    assign(socket, :snapshot, Kube.get_preloaded_kube_snapshot!(id))
  end

  defp assign_umbrella_id(socket, id) do
    assign(socket, :umbrella_id, id)
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title="Kubernetes Deploy" back_link={~p"/deploy/#{@umbrella_id}/show"}>
      <.flex>
        <.badge>
          <:item label="Status">{@snapshot.status}</:item>
          <:item label="Started">
            <.relative_display time={@snapshot.inserted_at} />
          </:item>
        </.badge>
      </.flex>
    </.page_header>

    <.panel title="Path Results">
      <.resource_paths_table rows={@snapshot.resource_paths} />
    </.panel>
    """
  end
end
