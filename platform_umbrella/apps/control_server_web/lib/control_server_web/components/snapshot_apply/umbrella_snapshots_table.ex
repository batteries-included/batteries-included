defmodule ControlServerWeb.UmbrellaSnapshotsTable do
  @moduledoc false
  use ControlServerWeb, :html

  attr :snapshots, :list, required: true
  attr :abbridged, :boolean, default: false, doc: "the abbridged property control display of the id column and formatting"

  def umbrella_snapshots_table(assigns) do
    ~H"""
    <.table rows={@snapshots}>
      <:col :let={snapshot} :if={!@abbridged} label="ID">
        <%= snapshot.id %>
      </:col>
      <:col :let={snapshot} label="Started">
        <%= Timex.format!(snapshot.inserted_at, "{RFC822z}") %>
      </:col>

      <:col :let={snapshot} label="Kube Status">
        <.kube_status snapshot={snapshot.kube_snapshot} />
      </:col>
      <:col :let={snapshot} label="Keycloak Status">
        <.keycloak_snapshot snapshot={snapshot.keycloak_snapshot} />
      </:col>
      <:action :let={snapshot}>
        <.a navigate={~p"/snapshot_apply/#{snapshot.kube_snapshot.id}/show"} variant="styled">
          Show Deploy
        </.a>
      </:action>
    </.table>
    """
  end

  attr :snapshot, :any

  defp kube_status(%{snapshot: nil} = assigns) do
    ~H"""
    Skipped
    """
  end

  defp kube_status(assigns) do
    ~H"""
    <%= @snapshot.status %>
    """
  end

  attr :snapshot, :any

  defp keycloak_snapshot(%{snapshot: nil} = assigns) do
    ~H"""
    Skipped
    """
  end

  defp keycloak_snapshot(%{} = assigns) do
    ~H"""
    <%= @snapshot.status %>
    """
  end
end
