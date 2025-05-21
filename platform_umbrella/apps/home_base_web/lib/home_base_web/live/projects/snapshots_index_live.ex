defmodule HomeBaseWeb.Projects.SnapshotsIndexLive do
  @moduledoc false

  use HomeBaseWeb, :live_view

  alias HomeBaseWeb.UserAuth

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    owner = UserAuth.current_team_or_user(socket)
    snapshots = HomeBase.Projects.snapshots_for(owner)

    {:ok,
     socket
     |> assign(:page, :snapshots)
     |> assign(:page_title, "Project Snapshots")
     |> assign(:snapshots, snapshots)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.h2>{@page_title}</.h2>

    <.table id="snapshots" rows={@snapshots}>
      <:col :let={stored_snap} label="ID">{stored_snap.id}</:col>
      <:col :let={stored_snap} label="Name">{stored_snap.name}</:col>
      <:col :let={stored_snap} label="Postgres Count">
        {stored_snap.num_postgres_clusters}
      </:col>
      <:col :let={stored_snap} label="Redis Count">
        {stored_snap.num_redis_instances}
      </:col>
      <:col :let={stored_snap} label="Jupyter Notebook Count">
        {stored_snap.num_jupyter_notebooks}
      </:col>
      <:col :let={stored_snap} label="Knative Service Count">
        {stored_snap.num_knative_services}
      </:col>
      <:col :let={stored_snap} label="Traditional Service Count">
        {stored_snap.num_traditional_services}
      </:col>
      <:col :let={stored_snap} label="Model Instance Count">
        {stored_snap.num_model_instances}
      </:col>
    </.table>
    """
  end
end
