defmodule ControlServerWeb.UmbrellaSnapshotsTable do
  @moduledoc false
  use ControlServerWeb, :html

  attr :snapshots, :list, required: true
  attr :meta, :map, default: nil
  attr :abridged, :boolean, default: false, doc: "the abridged property control display of the id column and formatting"
  attr :skip_date, :boolean, default: false, doc: "the abridged property control display of the id column and formatting"

  def umbrella_snapshots_table(assigns) do
    ~H"""
    <.table
      id="umbrella-snapshots-table"
      variant={@meta && "paginated"}
      rows={@snapshots}
      meta={@meta}
      path={~p"/deploy"}
      row_click={&JS.navigate(show_url(&1))}
    >
      <:col :let={snapshot} :if={!@abridged} field={:id} label="ID">
        {snapshot.id}
      </:col>
      <:col :let={snapshot} :if={!@skip_date} field={:inserted_at} label="Started">
        <.relative_display time={snapshot.inserted_at} />
      </:col>

      <:col :let={snapshot} field={:kube_snapshot} label="Kube Status">
        <.kube_status snapshot={snapshot.kube_snapshot} />
      </:col>
      <:col :let={snapshot} field={:keycloak_snapshot} label="Keycloak Status">
        <.keycloak_snapshot snapshot={snapshot.keycloak_snapshot} />
      </:col>
      <:action :let={snapshot}>
        <.button
          variant="minimal"
          link={show_url(snapshot)}
          icon={:eye}
          id={"show_deploy_" <> snapshot.id}
        />
        <.tooltip target_id={"show_deploy_" <> snapshot.id}>
          Show deploy
        </.tooltip>
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
    {@snapshot.status}
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
    {@snapshot.status}
    """
  end

  defp show_url(%{id: id}) do
    ~p"/deploy/#{id}/show"
  end
end
