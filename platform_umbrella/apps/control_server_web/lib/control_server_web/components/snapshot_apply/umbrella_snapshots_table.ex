defmodule ControlServerWeb.UmbrellaSnapshotsTable do
  @moduledoc false
  use ControlServerWeb, :html

  import CommonUI.DatetimeDisplay

  attr :snapshots, :list, required: true
  attr :abbridged, :boolean, default: false, doc: "the abbridged property control display of the id column and formatting"
  attr :skip_date, :boolean, default: false, doc: "the abbridged property control display of the id column and formatting"

  def umbrella_snapshots_table(assigns) do
    ~H"""
    <.table rows={@snapshots} row_click={&JS.navigate(show_url(&1))}>
      <:col :let={snapshot} :if={!@abbridged} label="ID">
        <%= snapshot.id %>
      </:col>
      <:col :let={snapshot} :if={!@skip_date} label="Started">
        <.relative_display time={snapshot.inserted_at} />
      </:col>

      <:col :let={snapshot} label="Kube Status">
        <.kube_status snapshot={snapshot.kube_snapshot} />
      </:col>
      <:col :let={snapshot} label="Keycloak Status">
        <.keycloak_snapshot snapshot={snapshot.keycloak_snapshot} />
      </:col>
      <:action :let={snapshot}>
        <.action_icon
          to={show_url(snapshot)}
          icon={:eye}
          tooltip="Show deploy"
          id={"show_deploy_" <> snapshot.id}
        />
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

  defp show_url(%{id: id}) do
    ~p"/deploy/#{id}/show"
  end
end
