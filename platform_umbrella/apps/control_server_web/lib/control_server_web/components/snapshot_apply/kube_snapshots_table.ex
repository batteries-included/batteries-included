defmodule ControlServerWeb.KubeSnapshotsTable do
  use ControlServerWeb, :html

  attr :kube_snapshots, :list, required: true

  def kube_snapshots_table(assigns) do
    ~H"""
    <.table rows={@kube_snapshots}>
      <:col :let={snapshot} label="ID">
        <%= snapshot.id %>
      </:col>
      <:col :let={snapshot} label="Started">
        <%= Timex.format!(snapshot.inserted_at, "{RFC822z}") %>
      </:col>
      <:col :let={snapshot} label="Status"><%= snapshot.status %></:col>
      <:action :let={snapshot}>
        <.link navigate={~p"/snapshot_apply/#{snapshot}/show"} variant="styled">Show Deploy</.link>
      </:action>
    </.table>
    """
  end
end
