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
      <:col :let={snapshot} label="Name">{snapshot.name}</:col>
      <:col :let={snapshot} label="Postgres Count">
        {length(snapshot.postgres_clusters || [])}
      </:col>
      <:col :let={snapshot} label="Redis Count">
        {length(snapshot.redis_instances || [])}
      </:col>
      <:col :let={snapshot} label="Jupyter Notebook Count">
        {length(snapshot.jupyter_notebooks || [])}
      </:col>
      <:col :let={snapshot} label="Knative Service Count">
        {length(snapshot.knative_services || [])}
      </:col>
      <:col :let={snapshot} label="Traditional Service Count">
        {length(snapshot.traditional_services || [])}
      </:col>
      <:col :let={snapshot} label="Model Instance Count">
        {length(snapshot.model_instances || [])}
      </:col>
    </.table>
    """
  end
end
